import 'connector.dart';

enum StationType { ac, dc, unknown }

class ChargingStation {
  final String serial;
  final String name;
  final String? address;
  final StationType type;
  final String? vendor;
  final String? model;
  final List<Connector> connectors;
  ChargingStation({
    required this.serial,
    required this.name,
    this.address,
    required this.type,
    this.vendor,
    this.model,
    required this.connectors,
  });
  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    final serial = json['id']?.toString() ?? 'Seri No Yok';
    final isInactive = json['inactive'] == true;

    var connectorsList = (json['connectors'] as List? ?? [])
        .map((c) => Connector.fromJson(c as Map<String, dynamic>, serial))
        .toList();

    // İstasyon inactive ise tüm konnektörleri arızalı olarak işaretle
    if (isInactive) {
      for (var connector in connectorsList) {
        connector.status = ConnectorStatus.offline;
      }
    }

    StationType stationType = StationType.unknown;
    if (connectorsList.isNotEmpty) {
      String typeStr = connectorsList.first.powerType;
      if (typeStr.toUpperCase() == 'AC') {
        stationType = StationType.ac;
      } else if (typeStr.toUpperCase() == 'DC') {
        stationType = StationType.dc;
      }
    }
    String? formattedAddress;
    final addressMap = json['siteArea']?['address'];
    if (addressMap is Map) {
      formattedAddress =
          '${addressMap['address1'] ?? ''}, ${addressMap['department'] ?? ''} / ${addressMap['region'] ?? ''}'
              .replaceAll(' ,', ',');
    }
    return ChargingStation(
      serial: serial,
      name: (json['siteArea']?['name'] as String? ?? 'İsimsiz İstasyon')
          .replaceAll('\t', ' '),
      address: formattedAddress,
      vendor: json['chargePointVendor']?.toString(),
      model: json['chargePointModel']?.toString(),
      connectors: connectorsList,
      type: stationType,
    );
  }
}
