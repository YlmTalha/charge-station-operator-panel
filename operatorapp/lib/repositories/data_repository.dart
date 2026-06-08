import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/charging_station.dart';
import '../models/charging_history.dart';
import '../models/history_stats.dart';
import '../models/connector.dart';
import '../models/charging_data.dart';
import '../services/auth_service.dart';

class DataRepository {
  static Future<List<ChargingStation>> fetchLiveStations() async {
    final authService = AuthService();
    String? token = await authService.getToken();

    if (token == null) {
      throw Exception('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
    }

    try {
      return await _fetchDataWithToken(token);
    } catch (e) {
      if (e.toString().contains('401')) {
        throw Exception('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchHistoryAndStats({
    DateTime? startDate,
    DateTime? endDate,
    int skip = 0,
    int limit = 50,
  }) async {
    final authService = AuthService();
    String? token = await authService.getToken();

    if (token == null) {
      throw Exception('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
    }

    // Tarih aralığını düzgün ayarla
    final start =
        startDate?.toUtc() ??
        DateTime.now().toUtc().subtract(const Duration(days: 30));
    final end = endDate?.toUtc() ?? DateTime.now().toUtc();

    try {
      return await _fetchHistoryWithToken(
        token,
        startDate: start,
        endDate: end,
        skip: skip,
        limit: limit,
      );
    } catch (e) {
      if (e.toString().contains('401')) {
        throw Exception('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
      }
      rethrow;
    }
  }

  // DÜZELTME: Bu metot artık doğru bir şekilde mevcut
  static Future<HistoryStats> fetchYearToDateStats() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, 1, 1);
    final result = await fetchHistoryAndStats(
      startDate: startDate,
      endDate: now,
      limit: 1, // Sadece stats verisi için 1 kayıt yeterli
    );
    return result['stats'] as HistoryStats;
  }

  static Future<List<ChargingStation>> _fetchDataWithToken(String token) async {
    final stationsUri = Uri.parse(ApiConfig.stationsUrl).replace(
      queryParameters: {
        'Issuer': 'true',
        'WithSite': 'true',
        'WithSiteArea': 'true',
        'Limit': '500',
      },
    );
    final transactionsUri = Uri.parse(ApiConfig.activeTransactionsUrl).replace(
      queryParameters: {
        'Issuer': 'true',
        'WithChargingStation': 'true',
        'WithUser': 'true',
        'WithCar': 'true',
        'Limit': '100',
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

  static Future<Map<String, dynamic>> _fetchHistoryWithToken(
    String token, {
    DateTime? startDate,
    DateTime? endDate,
    int skip = 0,
    int limit = 50,
  }) async {
    final baseParams = {
      'Issuer': 'true',
      'WithCompany': 'true',
      'WithSite': 'true',
      'WithSiteArea': 'true',
      'WithTag': 'true',
      'WithUser': 'true',
      'WithCar': 'true',
      'WithCurrentType': 'true',
      'Statistics': 'history',
      'WithChargingStation': 'false',
      'SortFields': '-timestamp',
      'BillingStatus': 'pending|failed|billed',
      'Skip': skip.toString(),
      'Limit': limit.toString(),
      'Status': 'completed',
    };

    // Tarihleri ISO8601 formatında gönder
    if (startDate != null) {
      baseParams['StartDateTime'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      baseParams['EndDateTime'] = endDate.toIso8601String();
    }

    // 1. Önce total değerleri alalım
    final totalParams = {...baseParams};
    totalParams['OnlyRecordCount'] = 'true';

    final totalUri = Uri.parse(
      ApiConfig.historyUrl,
    ).replace(queryParameters: totalParams);
    final totalResponse = await _fetchApi(totalUri, token);
    final totalDecoded = jsonDecode(utf8.decode(totalResponse.bodyBytes));
    final stats = HistoryStats.fromJson(
      totalDecoded['stats'] as Map<String, dynamic>?,
    );

    // 2. Sonra detaylı işlem geçmişini alalım
    final detailUri = Uri.parse(
      ApiConfig.historyUrl,
    ).replace(queryParameters: baseParams);
    final detailResponse = await _fetchApi(detailUri, token);
    final detailDecoded = jsonDecode(utf8.decode(detailResponse.bodyBytes));

    final historyList = (detailDecoded['result'] as List? ?? [])
        .where((json) => json['stop'] != null)
        .map((json) => ChargingHistory.fromJson(json as Map<String, dynamic>))
        .toList();

    return {'history': historyList, 'stats': stats};
  }

  static Future<http.Response> _fetchApi(Uri uri, String bearerToken) async {
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('API Hatası (${uri.path}): ${response.statusCode}');
    }
  }

  static String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }
}
