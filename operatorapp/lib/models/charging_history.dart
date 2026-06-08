import 'package:intl/intl.dart';

class ChargingHistory {
  final int id;
  final String date;
  final String timeRange;
  final String station;
  final String srmNumber;
  final String user;
  final int duration; // saniye cinsinden
  final double energy; // kWh cinsinden
  final double cost;
  final String powerType;

  ChargingHistory({
    required this.id,
    required this.date,
    required this.timeRange,
    required this.station,
    required this.srmNumber,
    required this.user,
    required this.duration,
    required this.energy,
    required this.cost,
    required this.powerType,
  });

  String get formattedDuration {
    final d = Duration(seconds: duration);
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}s ${minutes}dk';
    } else {
      return '${minutes}dk';
    }
  }

  factory ChargingHistory.fromJson(Map<String, dynamic> json) {
    final stopData = json['stop'];
    if (stopData == null) {
      return ChargingHistory(
        id: 0,
        date: 'Bilinmiyor',
        timeRange: 'Bilinmiyor',
        station: 'İsimsiz İstasyon',
        srmNumber: 'SRM Yok',
        user: 'Bilinmiyor',
        duration: 0,
        energy: 0,
        cost: 0,
        powerType: 'unknown',
      );
    }

    final startTime = DateTime.tryParse(json['timestamp'] ?? '')?.toLocal();
    final stopTime = DateTime.tryParse(stopData['timestamp'] ?? '')?.toLocal();

    final timeFormatter = DateFormat('HH:mm');
    final dateFormatter = DateFormat('dd.MM.yyyy');

    return ChargingHistory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      date: startTime != null ? dateFormatter.format(startTime) : 'Bilinmiyor',
      timeRange: (startTime != null && stopTime != null)
          ? '${timeFormatter.format(startTime)} - ${timeFormatter.format(stopTime)}'
          : 'Bilinmiyor',
      station: json['siteArea']?['name']?.toString() ?? 'İsimsiz İstasyon',
      srmNumber: json['chargeBoxID']?.toString() ?? 'SRM Yok',
      user: () {
        // Önce ana json'dan user bilgisini dene
        String firstName = json['user']?['firstName']?.toString() ?? '';
        String lastName = json['user']?['name']?.toString() ?? '';
        
        // Eğer ana json'da yoksa, stop data'dan dene
        if (firstName.isEmpty && lastName.isEmpty && stopData != null) {
          firstName = stopData['user']?['firstName']?.toString() ?? '';
          lastName = stopData['user']?['name']?.toString() ?? '';
        }
        
        final fullName = '$firstName $lastName'.trim();
        return fullName.isEmpty ? 'Bilinmiyor' : fullName;
      }(),
      duration: (stopData['totalDurationSecs'] as num?)?.toInt() ?? 0,
      energy: ((stopData['totalConsumptionWh'] as num?)?.toInt() ?? 0) / 1000.0,
      cost:
          (stopData['roundedPrice'] as num?)?.toDouble() ??
          (stopData['price'] as num?)?.toDouble() ??
          (stopData['totalPrice'] as num?)?.toDouble() ??
          0.0,
      powerType: json['connectorCurrentType'] ?? 'unknown',
    );
  }
}
