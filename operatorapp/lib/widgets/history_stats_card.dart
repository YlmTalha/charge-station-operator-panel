class HistoryStats {
  final double totalPrice;
  final double totalConsumptionWhAC;
  final double totalConsumptionWhDC;
  final int count;

  const HistoryStats({
    this.totalPrice = 0.0,
    this.totalConsumptionWhAC = 0.0,
    this.totalConsumptionWhDC = 0.0,
    this.count = 0,
  });

  // DÜZELTME: Wh'ı kWh'e çeviren yardımcı getter'lar
  double get totalConsumptionKWhAC => totalConsumptionWhAC / 1000.0;
  double get totalConsumptionKWhDC => totalConsumptionWhDC / 1000.0;

  factory HistoryStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HistoryStats();
    return HistoryStats(
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      totalConsumptionWhAC:
          (json['totalConsumptionWattHoursAC'] as num?)?.toDouble() ?? 0.0,
      totalConsumptionWhDC:
          (json['totalConsumptionWattHoursDC'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
