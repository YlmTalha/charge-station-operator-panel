import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ConnectorIcons {
  // Modern DC Connector Icon
  static Widget dcIcon({double size = 24, Color? color}) {
    final iconColor = color ?? AppTheme.chargingColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            iconColor.withOpacity(0.3),
            iconColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: iconColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'DC',
          style: TextStyle(
            color: iconColor,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // Modern AC Connector Icon
  static Widget acIcon({double size = 24, Color? color}) {
    final iconColor = color ?? AppTheme.availableColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            iconColor.withOpacity(0.3),
            iconColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: iconColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'AC',
          style: TextStyle(
            color: iconColor,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // Modern DC Station Icon
  static Widget dcStationEmoji({double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.successGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.flash_on_rounded,
          size: size * 0.6,
          color: Colors.white,
        ),
      ),
    );
  }

  // Modern AC Station Icon
  static Widget acStationEmoji({double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.infoColor, AppTheme.availableColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.infoColor.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.power_rounded,
          size: size * 0.6,
          color: Colors.white,
        ),
      ),
    );
  }

  // Modern DC-1 Connector Icon
  static Widget dc1Icon({double size = 24, Color? color}) {
    final iconColor = color ?? AppTheme.chargingColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            iconColor.withOpacity(0.3),
            iconColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: iconColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '1',
          style: TextStyle(
            color: iconColor,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // Modern DC-2 Connector Icon
  static Widget dc2Icon({double size = 24, Color? color}) {
    final iconColor = color ?? AppTheme.chargingColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            iconColor.withOpacity(0.3),
            iconColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: iconColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '2',
          style: TextStyle(
            color: iconColor,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}