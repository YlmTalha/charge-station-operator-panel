import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/charging_station.dart';
import '../../models/connector.dart';
import '../../widgets/connector_icons.dart';

class ActiveTab extends StatelessWidget {
  final List<Connector> activeConnectors;
  final List<ChargingStation> liveStations;
  final ScrollController? scrollController;
  const ActiveTab({
    super.key,
    required this.activeConnectors,
    required this.liveStations,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (activeConnectors.isEmpty) {
      return SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.chargingColor.withOpacity(0.1),
                        AppTheme.chargingColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.chargingColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.flash_on_rounded,
                    size: 64,
                    color: AppTheme.chargingColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Aktif şarj işlemi yok",
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Şarj işlemi başladığında burada görüntülenecek",
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: activeConnectors.length,
      itemBuilder: (context, index) {
        final c = activeConnectors[index];
        final station = liveStations.firstWhere(
          (s) => s.serial == c.parentStationSerial,
          orElse: () => ChargingStation(
            serial: '',
            name: 'Bilinmeyen İstasyon',
            connectors: [],
            type: StationType.unknown,
          ),
        );
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.elevatedShadow,
            border: Border.all(
              color: AppTheme.cardBorder.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Modern station header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusLarge),
                    topRight: Radius.circular(AppTheme.radiusLarge),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryAccent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    c.powerType == 'DC'
                        ? ConnectorIcons.dcStationEmoji(size: 28)
                        : ConnectorIcons.acStationEmoji(size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            station.serial,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: c.powerType == 'DC'
                          ? (c.id == 1
                                ? ConnectorIcons.dc1Icon(
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : ConnectorIcons.dc2Icon(
                                    size: 18,
                                    color: Colors.white,
                                  ))
                          : ConnectorIcons.acIcon(
                              size: 18,
                              color: Colors.white,
                            ),
                    ),
                  ],
                ),
              ),
              // Modern content section
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          c.powerType == 'DC'
                              ? Icons.flash_on_rounded
                              : Icons.power_rounded,
                          color: AppTheme.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          c.powerType == 'DC'
                              ? 'DC-Konnektör ${c.id}'
                              : 'AC Konnektör',
                          style: AppTheme.headingSmall.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                c.status.displayColor.withOpacity(0.2),
                                c.status.displayColor.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                            border: Border.all(
                              color: c.status.displayColor.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            c.status.displayText,
                            style: AppTheme.caption.copyWith(
                              color: c.status.displayColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Modern user information section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.surfaceDark,
                            AppTheme.surfaceDark.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        border: Border.all(
                          color: AppTheme.textMuted.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  c.userFullName ?? 'Kullanıcı Bilinmiyor',
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.infoColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.directions_car_rounded,
                                  color: AppTheme.infoColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: c.userCarPlate ?? 'Plaka Yok',
                                        style: AppTheme.bodyMedium.copyWith(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      if (c.userCarName != null ||
                                          c.userCarModel != null) ...[
                                        TextSpan(
                                          text: ' • ',
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                        TextSpan(
                                          text: [c.userCarName, c.userCarModel]
                                              .where(
                                                (s) =>
                                                    s != null && s.isNotEmpty,
                                              )
                                              .join(' '),
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.textTertiary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Charging statistics - Modern Cards
                    Row(
                      children: [
                        // Duration with gradient
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.infoColor.withOpacity(0.12),
                                  AppTheme.infoColor.withOpacity(0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.infoColor.withOpacity(0.35),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.infoColor.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.infoGradient,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.infoColor.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.access_time,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  c.chargingData?.elapsed ?? '00:00:00',
                                  style: TextStyle(
                                    color: AppTheme.infoColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'monospace',
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Süre',
                                  style: TextStyle(
                                    color: AppTheme.infoColor.withOpacity(0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Power with gradient
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.chargingColor.withOpacity(0.12),
                                  AppTheme.chargingColor.withOpacity(0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.chargingColor.withOpacity(0.35),
                                width: 1.5,
                              ),
                              boxShadow: AppTheme.tealGlowShadow,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.tealGradient,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.chargingColor
                                            .withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.flash_on,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      c.chargingData?.currentPower
                                              .toStringAsFixed(1) ??
                                          '0.0',
                                      style: TextStyle(
                                        color: AppTheme.chargingColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 1),
                                      child: Text(
                                        'kW',
                                        style: TextStyle(
                                          color: AppTheme.chargingColor
                                              .withOpacity(0.8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Güç',
                                  style: TextStyle(
                                    color: AppTheme.chargingColor.withOpacity(
                                      0.8,
                                    ),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Modern cost highlight
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.priceGradient,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        boxShadow: AppTheme.priceGlowShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.currency_lira,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${c.chargingData?.cost.toStringAsFixed(2) ?? '0.00'} TL',
                            style: AppTheme.headingMedium.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
