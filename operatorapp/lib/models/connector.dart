import 'package:flutter/material.dart';
import 'charging_data.dart';

enum ConnectorStatus {
  available,
  charging,
  starting,
  finishing,
  offline,
  unknown,
}

extension ConnectorStatusX on ConnectorStatus {
  String get displayText {
    switch (this) {
      case ConnectorStatus.available:
        return 'Müsait';
      case ConnectorStatus.charging:
        return 'Şarj Ediyor';
      case ConnectorStatus.starting:
        return 'Hazırlanıyor';
      case ConnectorStatus.finishing:
        return 'Bitiriliyor';
      case ConnectorStatus.offline:
        return 'Arızalı';
      default:
        return 'Bilinmiyor';
    }
  }

  Color get displayColor {
    switch (this) {
      case ConnectorStatus.available:
        return const Color(0xFF10B981);
      case ConnectorStatus.charging:
        return const Color(0xFF3B82F6);
      case ConnectorStatus.starting:
        return const Color(0xFFFCD34D);
      case ConnectorStatus.finishing:
        return const Color(0xFFFF6B35);
      case ConnectorStatus.offline:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class Connector {
  final int id;
  final String label;
  ConnectorStatus status;
  final String powerType;
  final String connectorType;
  final int maxPowerWatts;
  final String parentStationSerial;
  ChargingData? chargingData;
  String? userCarPlate;
  String? userCarName;
  String? userCarModel;
  String? userFullName;
  String? errorInfo;
  Connector({
    required this.id,
    required this.label,
    required this.status,
    required this.powerType,
    required this.connectorType,
    required this.maxPowerWatts,
    required this.parentStationSerial,
    this.chargingData,
    this.userCarPlate,
    this.userCarName,
    this.userCarModel,
    this.userFullName,
    this.errorInfo,
  });
  factory Connector.fromJson(Map<String, dynamic> json, String stationSerial) {
    return Connector(
      id: (json['connectorId'] as num?)?.toInt() ?? 0,
      label: "Konnektör ${json['connectorId'] ?? '?'}",
      status: Connector.parseStatus(
        json['status']?.toString(),
        json['errorCode']?.toString(),
      ),
      powerType: json['currentType']?.toString() ?? 'Bilinmiyor',
      connectorType: json['type']?.toString() ?? 'Bilinmiyor',
      maxPowerWatts: (json['power'] as num?)?.round() ?? 0,
      parentStationSerial: stationSerial,
      errorInfo: json['info']?.toString(),
    );
  }
  static ConnectorStatus parseStatus(String? status, String? errorCode) {
    if (errorCode != null && errorCode != "NoError") {
      return ConnectorStatus.offline;
    }
    switch (status?.toLowerCase()) {
      case "available":
        return ConnectorStatus.available;
      case "preparing":
        return ConnectorStatus.starting;
      case "charging":
        return ConnectorStatus.charging;
      case "finishing":
        return ConnectorStatus.finishing;
      case "faulted":
        return ConnectorStatus.offline;
      default:
        return ConnectorStatus.unknown;
    }
  }
}
