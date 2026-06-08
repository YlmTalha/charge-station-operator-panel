class ChargingData {
  double currentPower;
  final int maxPower;
  final double rate;
  String elapsed;
  double cost;
  double totalEnergyKwh;
  ChargingData({
    required this.currentPower,
    required this.maxPower,
    required this.rate,
    required this.elapsed,
    required this.cost,
    required this.totalEnergyKwh,
  });
}
