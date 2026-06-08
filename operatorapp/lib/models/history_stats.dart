import 'package:intl/intl.dart';

class HistoryStats {
  final double totalPrice;
  final double totalConsumptionWh;
  final int count;
  final DateTime? firstTimestamp;
  final DateTime? lastTimestamp;
  final double totalDurationSecs;
  final int totalRecords; // Toplam kayıt sayısı için yeni alan

  const HistoryStats({
    this.totalPrice = 0.0,
    this.totalConsumptionWh = 0.0,
    this.count = 0,
    this.firstTimestamp,
    this.lastTimestamp,
    this.totalDurationSecs = 0.0,
    this.totalRecords = 0, // Varsayılan değer 0
  });

  // İsterseniz her zaman binlik ayraç + 2 ondalık kullanın
  String get formattedPrice {
    final f = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    );
    return f.format(totalPrice);
  }

  double get totalConsumptionKWh => totalConsumptionWh / 1000.0;

  String get formattedDuration {
    final d = Duration(seconds: totalDurationSecs.round());
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '$hours saat $minutes dakika';
  }

  factory HistoryStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HistoryStats();

    // API'den direkt dönüş değerlerini alıyoruz
    return HistoryStats(
      totalPrice:
          (json['roundedTotalPrice'] as num?)?.toDouble() ??
          (json['totalPrice'] as num?)?.toDouble() ??
          0.0,
      totalConsumptionWh:
          (json['totalConsumptionWattHours'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      firstTimestamp: json['firstTimestamp'] != null
          ? DateTime.parse(json['firstTimestamp'] as String).toLocal()
          : null,
      lastTimestamp: json['lastTimestamp'] != null
          ? DateTime.parse(json['lastTimestamp'] as String).toLocal()
          : null,
      totalDurationSecs: (json['totalDurationSecs'] as num?)?.toDouble() ?? 0.0,
      totalRecords: (json['lastOneMonthTransaction'] as num?)?.toInt() ?? 0,
    );
  }
}
