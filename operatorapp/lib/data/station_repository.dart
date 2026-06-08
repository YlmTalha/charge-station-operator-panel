import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/charging_station.dart';
import '../models/charging_history.dart';
import '../models/history_stats.dart';
import '../models/connector.dart';
import '../models/charging_data.dart';
import '../utils/api_debug_helper.dart';

class StationRepository {
  // ANLIK VE AKTİF SEKMELERİ İÇİN VERİ ÇEKER
  static Future<List<ChargingStation>> fetchLiveStations() async {
    debugPrint("Anlık veriler çekiliyor...");
    // ApiHelper otomatik olarak token kontrolü ve yeniden giriş işlemini hallediyor
    return await _fetchDataWithToken(
      'dummy',
    ); // Token parametresi artık kullanılmıyor
  }

  // GEÇMİŞ SEKMESİ İÇİN VERİ ÇEKER
  static Future<Map<String, dynamic>> fetchHistoryAndStats({
    DateTime? startDate,
    DateTime? endDate,
    int skip = 0,
    int limit = 50,
  }) async {
    debugPrint("Geçmiş veriler çekiliyor...");
    return await _fetchHistoryWithToken(
      'dummy',
      startDate: startDate,
      endDate: endDate,
      skip: skip,
      limit: limit,
    );
  }

  /// AC veya DC filtresine göre tüm kayıtları çekip istatistikleri hesaplar
  static Future<Map<String, dynamic>> fetchFilteredStats({
    DateTime? startDate,
    DateTime? endDate,
    required String powerType, // 'AC' veya 'DC'
  }) async {
    debugPrint("$powerType filtrelenmiş istatistikler çekiliyor...");
    // Tüm kayıtları yüksek limit ile çek
    final result = await _fetchHistoryWithToken(
      'dummy',
      startDate: startDate,
      endDate: endDate,
      skip: 0,
      limit: 5000,
    );
    final allHistory = result['history'] as List<ChargingHistory>;
    // powerType'a göre filtrele
    final filtered = allHistory.where((h) => h.powerType == powerType).toList();
    // İstatistikleri hesapla
    final filteredStats = HistoryStats(
      totalPrice: filtered.fold(0.0, (sum, h) => sum + h.cost),
      totalConsumptionWh: filtered.fold(0.0, (sum, h) => sum + h.energy) * 1000,
      count: filtered.length,
      totalDurationSecs: filtered.fold(0.0, (sum, h) => sum + h.duration.toDouble()),
    );
    return {'history': filtered, 'stats': filteredStats};
  }

  // --- ÖZEL YARDIMCI METOTLAR ---

  // Canlı verileri çeken ve birleştiren ana mantık
  static Future<List<ChargingStation>> _fetchDataWithToken(String token) async {
    final stationsUri = Uri.parse(ApiConfig.stationsUrl).replace(
      queryParameters: {
        'Issuer': 'true',
        'WithSite': 'true',
        'WithSiteArea': 'true',
        'WithUser': 'true',
        'WithStatistic': 'true',
        'Limit': '50',
        'SortFields': 'id',
      },
    );
    final transactionsUri = Uri.parse(ApiConfig.activeTransactionsUrl).replace(
      queryParameters: {
        'Issuer': 'true',
        'WithCompany': 'true',
        'WithSite': 'true',
        'WithSiteArea': 'true',
        'WithTag': 'true',
        'WithUser': 'true',
        'WithCar': 'true',
        'WithChargingStation': 'true',
        'Statistics': 'ongoing',
        'Limit': '50',
        'SortFields': '-timestamp',
      },
    );

    final responses = await Future.wait([
      _fetchApi(stationsUri, token),
      _fetchApi(transactionsUri, token),
    ]);

    final stationsJson =
        jsonDecode(utf8.decode(responses[0].bodyBytes))['result'] as List? ??
        [];
    final transactionsJson =
        jsonDecode(utf8.decode(responses[1].bodyBytes))['result'] as List? ??
        [];

    List<ChargingStation> allStations = stationsJson
        .map((json) => ChargingStation.fromJson(json as Map<String, dynamic>))
        .toList();
    final Map<String, dynamic> activeTransactionsMap = {
      for (var tx in transactionsJson)
        if (tx is Map<String, dynamic> &&
            tx['chargeBoxID'] != null &&
            tx['connectorId'] != null)
          '${tx['chargeBoxID']}-${tx['connectorId']}': tx,
    };

    for (var station in allStations) {
      for (var connector in station.connectors) {
        final key = '${station.serial}-${connector.id}';
        if (activeTransactionsMap.containsKey(key)) {
          final txData = activeTransactionsMap[key];

          connector.status = Connector.parseStatus(
            txData['status']?.toString(),
            txData['errorCode']?.toString(),
          );
          connector.userCarPlate = txData['userCar']?['plateID'];
          connector.userCarName = txData['userCar']?['name'];
          connector.userCarModel = txData['userCar']?['model']?['name'];
          connector.userFullName =
              "${txData['user']?['firstName'] ?? ''} ${txData['user']?['name'] ?? ''}"
                  .trim();

          final energyPrice =
              (txData['businessData']?['energyPrice'] as num? ?? 0).toDouble();
          final rate = energyPrice > 0
              ? energyPrice
              : (connector.powerType == 'DC' ? 8.50 : 4.25);

          connector.chargingData = ChargingData(
            currentPower: (txData['currentInstantWatts'] as num? ?? 0) / 1000.0,
            maxPower: connector.maxPowerWatts ~/ 1000,
            totalEnergyKwh:
                (txData['currentTotalConsumptionWh'] as num? ?? 0) / 1000.0,
            cost:
                (txData['totalPrice'] as num? ??
                        txData['currentCumulatedPrice'] as num? ??
                        0)
                    .toDouble(),
            rate: rate,
            elapsed: _formatDuration(
              (txData['currentTotalDurationSecs'] as num?)?.toInt() ?? 0,
            ),
          );
        }
      }
    }
    return allStations;
  }

  // API için temel parametreleri oluşturan yardımcı metot
  static Map<String, String> _getBaseHistoryParams({
    int skip = 0,
    int limit = 50,
  }) {
    return {
      'Issuer': 'true',
      'WithCompany': 'true',
      'WithSite': 'true',
      'WithSiteArea': 'true',
      'WithTag': 'true',
      'WithUser': 'true',
      'WithCar': 'true',
      'WithCurrentType': 'true',
      'BillingStatus': 'pending|failed|billed',
      'Limit': limit.toString(),
      'Skip': skip.toString(),
      'SortFields': '-timestamp',
    };
  }

  // Toplam istatistikler için ek parametreleri ekleyen yardımcı metot
  static Map<String, String> _getTotalStatsParams({
    required DateTime? startDate,
    required DateTime? endDate,
  }) {
    final params = {
      ..._getBaseHistoryParams(limit: 50),
      'Statistics': 'history',
      'WithChargingStation': 'false',
      'OnlyRecordCount': 'true',
    };

    if (startDate != null) {
      params['StartDateTime'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      params['EndDateTime'] = endDate.toUtc().toIso8601String();
    }

    return params;
  }

  static Future<Map<String, dynamic>> _fetchHistoryWithToken(
    String token, {
    DateTime? startDate,
    DateTime? endDate,
    int skip = 0,
    int limit = 50,
  }) async {
    // Temel parametreleri al
    final params = _getBaseHistoryParams(skip: skip, limit: limit);

    // Tarih parametrelerini ekle
    if (startDate != null) {
      params['StartDateTime'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      params['EndDateTime'] = endDate.toUtc().toIso8601String();
    }

    // İstatistikler için ayrı bir istek yap
    final statsParams = _getTotalStatsParams(
      startDate: startDate,
      endDate: endDate,
    );

    final historyUri = Uri.parse(
      ApiConfig.historyUrl,
    ).replace(queryParameters: params);
    final statsUri = Uri.parse(
      ApiConfig.historyUrl,
    ).replace(queryParameters: statsParams);

    final responses = await Future.wait([
      _fetchApi(historyUri, token),
      _fetchApi(statsUri, token),
    ]);

    final historyData = jsonDecode(utf8.decode(responses[0].bodyBytes));
    final statsData = jsonDecode(utf8.decode(responses[1].bodyBytes));

    final historyList = (historyData['result'] as List? ?? [])
        .where((json) => json['stop'] != null)
        .map((json) => ChargingHistory.fromJson(json as Map<String, dynamic>))
        .toList();

    final stats = HistoryStats.fromJson(
      statsData['stats'] as Map<String, dynamic>?,
    );

    // İstatistiklerdeki toplam kayıt sayısını ekle - HistoryStats sınıfını immutable yapmak için yeniden oluştur
    final updatedStats = HistoryStats(
      totalPrice: stats.totalPrice,
      totalConsumptionWh: stats.totalConsumptionWh,
      count: stats.count,
      firstTimestamp: stats.firstTimestamp,
      lastTimestamp: stats.lastTimestamp,
      totalDurationSecs: stats.totalDurationSecs,
      totalRecords: (statsData['count'] as num?)?.toInt() ?? 0,
    );

    return {'history': historyList, 'stats': updatedStats};
  }

  // Genel API çağırma metodu - ApiHelper kullanılıyor
  static Future<http.Response> _fetchApi(Uri uri, String bearerToken) async {
    try {
      return await ApiHelper.get(uri);
    } catch (e) {
      debugPrint('API çağrısı sırasında hata: $e');
      rethrow;
    }
  }

  // Saniyeyi HH:MM:SS formatına çeviren metot
  static String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}
