import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../models/charging_station.dart';
import '../../models/connector.dart';
import '../../widgets/connector_icons.dart';
import '../../config/app_theme.dart';

class LiveTab extends StatefulWidget {
  final List<ChargingStation> stations;
  final ScrollController? scrollController;
  const LiveTab({super.key, required this.stations, this.scrollController});
  @override
  State<LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends State<LiveTab> {
  String _typeFilter = 'all';
  String _statusFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Connector> get _allConnectors =>
      widget.stations.expand((s) => s.connectors).toList();

  List<Connector> get _filteredConnectors {
    return _allConnectors.where((c) {
      final typeMatch = _typeFilter == 'all' || c.powerType == _typeFilter;
      final statusName = c.status.name;
      final statusMatch = _statusFilter == 'all' || statusName == _statusFilter;

      // Search filter for station name or ID containing the search query
      bool searchMatch = true;
      if (_searchQuery.isNotEmpty) {
        final station = widget.stations.firstWhere(
          (s) => s.serial == c.parentStationSerial,
        );
        searchMatch =
            station.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            station.serial.toLowerCase().contains(_searchQuery.toLowerCase());
      }

      return typeMatch && statusMatch && searchMatch;
    }).toList();
  }

  List<Connector> get _activeConnectors => _allConnectors
      .where(
        (c) =>
            c.status == ConnectorStatus.charging ||
            c.status == ConnectorStatus.starting,
      )
      .toList();
  double get _totalActivePower => _activeConnectors.fold(
    0.0,
    (sum, c) => sum + (c.chargingData?.currentPower ?? 0.0),
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupedByStation = groupBy(
      _filteredConnectors,
      (Connector c) => c.parentStationSerial,
    );
    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildQuickStats(),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          if (groupedByStation.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      _searchQuery.isNotEmpty
                          ? Icons.search_off
                          : Icons.filter_list_off,
                      size: 64,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Arama sonucu bulunamadı'
                          : 'Filtreye uygun istasyon bulunamadı',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty
                          ? '"$_searchQuery" için sonuç bulunamadı'
                          : 'Farklı filtre seçenekleri deneyebilirsiniz',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...groupedByStation.entries.map((entry) {
              final stationConnectors = entry.value;
              final station = widget.stations.firstWhere(
                (s) => s.serial == entry.key,
              );
              const priority = [
                ConnectorStatus.charging,
                ConnectorStatus.starting,
                ConnectorStatus.offline,
                ConnectorStatus.available,
              ];
              final stationStatus = stationConnectors
                  .map((c) => c.status)
                  .sorted((a, b) => priority.indexOf(a) - priority.indexOf(b))
                  .first;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceDark),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    _buildStationHeader(stationStatus, station),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: stationConnectors
                            .map((c) => _buildConnectorCard(c))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.elevatedShadow,
        border: Border.all(
          color: AppTheme.cardBorder.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard_outlined,
                  color: AppTheme.primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anlık Durum Özeti',
                      style: AppTheme.headingMedium.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.stations.length} İstasyon • ${_allConnectors.length} Konnektör',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Üst satır - Müsait ve Arızalı yan yana (KÜÇÜK)
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.check_circle_outline,
                  label: 'Müsait',
                  value: _allConnectors
                      .where((c) => c.status == ConnectorStatus.available)
                      .length
                      .toString(),
                  color: AppTheme.availableColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Arızalı',
                  value: _allConnectors
                      .where((c) => c.status == ConnectorStatus.offline)
                      .length
                      .toString(),
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Aktif Güç - Altta tek (BÜYÜK)
          _buildMainStatCard(
            icon: Icons.flash_on,
            label: 'Anlık Toplam Güç',
            value: '${_totalActivePower.toStringAsFixed(1)} kW',
            subtitle: '${_activeConnectors.length} konnektör aktif',
            color: AppTheme.chargingColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatCard({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    // Teal için gradient seç
    final gradient = color == AppTheme.chargingColor
        ? AppTheme.tealGradient
        : LinearGradient(colors: [color, color.withOpacity(0.8)]);

    final glow = color == AppTheme.chargingColor
        ? AppTheme.tealGlowShadow
        : [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: glow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // KÜÇÜK KOMPAKT KARTLAR (Müsait/Arızalı için)
  Widget _buildCompactStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    // Available için blue, Error için red gradient
    final gradient = color == AppTheme.availableColor
        ? AppTheme.infoGradient
        : AppTheme.errorGradient;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akıllı Filtreler',
            style: AppTheme.headingMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),

          // Search Bar Section
          Text(
            'İSTASYON ARAMA',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.isDarkMode
                  ? AppTheme.surfaceDark
                  : Colors.white, // Light mode: beyaz
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.isDarkMode
                    ? AppTheme.textMuted.withOpacity(0.3)
                    : const Color(0xFFD1D5DB), // Light: daha belirgin border
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'İsim veya ID ile ara...',
                hintStyle: TextStyle(
                  color: AppTheme.isDarkMode
                      ? AppTheme.textMuted
                      : const Color(0xFF9CA3AF), // Light: daha koyu hint
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.isDarkMode
                      ? AppTheme.textMuted
                      : const Color(0xFF6B7280), // Light: daha koyu icon
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppTheme.isDarkMode
                              ? AppTheme.textMuted
                              : const Color(0xFF6B7280),
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'İSTASYON TİPİ',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFilterButton(
                'all',
                'Tümü',
                _typeFilter,
                (val) => setState(() => _typeFilter = val),
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                'AC',
                'AC',
                _typeFilter,
                (val) => setState(() => _typeFilter = val),
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                'DC',
                'DC',
                _typeFilter,
                (val) => setState(() => _typeFilter = val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'DURUM FİLTRESİ',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterButton(
                'all',
                'Tümü',
                _statusFilter,
                (val) => setState(() => _statusFilter = val),
                isRow: false,
              ),
              _buildFilterButton(
                'available',
                'Müsait',
                _statusFilter,
                (val) => setState(() => _statusFilter = val),
                isRow: false,
              ),
              _buildFilterButton(
                'charging',
                'Şarjda',
                _statusFilter,
                (val) => setState(() => _statusFilter = val),
                isRow: false,
              ),
              _buildFilterButton(
                'starting',
                'Hazırlanıyor',
                _statusFilter,
                (val) => setState(() => _statusFilter = val),
                isRow: false,
              ),
              _buildFilterButton(
                'offline',
                'Arızalı',
                _statusFilter,
                (val) => setState(() => _statusFilter = val),
                isRow: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    String value,
    String text,
    String groupValue,
    ValueChanged<String> onChanged, {
    bool isRow = true,
  }) {
    final isSelected = groupValue == value;
    final button = ElevatedButton(
      onPressed: () => onChanged(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? AppTheme.primaryAccent
            : (AppTheme.isDarkMode
                  ? AppTheme.cardDark
                  : Colors.white), // Light: beyaz buton
        foregroundColor: isSelected
            ? Colors.white
            : (AppTheme.isDarkMode
                  ? AppTheme.textSecondary
                  : const Color(0xFF374151)), // Light: koyu yazı
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: isSelected ? 4 : 0,
        shadowColor: isSelected
            ? AppTheme.primaryAccent.withOpacity(0.4)
            : Colors.transparent,
        side: isSelected
            ? null
            : BorderSide(
                color: AppTheme.isDarkMode
                    ? AppTheme.cardBorder.withOpacity(0.5)
                    : const Color(0xFFD1D5DB), // Light: belirgin border
                width: 1.5,
              ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: isSelected
              ? Colors.white
              : (AppTheme.isDarkMode
                    ? AppTheme.textSecondary
                    : const Color(0xFF374151)), // Light: koyu yazı
        ),
      ),
    );
    return isRow ? Expanded(child: button) : button;
  }

  Widget _buildStationHeader(ConnectorStatus status, ChargingStation station) {
    final isDC = station.connectors.any((c) => c.powerType == 'DC');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusMedium),
          topRight: Radius.circular(AppTheme.radiusMedium),
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
          // Station type emoji/icon
          isDC
              ? ConnectorIcons.dcStationEmoji(size: 36)
              : ConnectorIcons.acStationEmoji(size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        station.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isDC ? 'DC İstasyonu' : 'AC İstasyonu',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.settings_input_component,
                      size: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      station.serial,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.circle, size: 8, color: status.displayColor),
                    const SizedBox(width: 4),
                    Text(
                      status.displayText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectorCard(Connector c) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.cardBorder.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: c.chargingData != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with connector info and status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.status.displayColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: c.powerType == 'DC'
                            ? (c.id == 1
                                  ? ConnectorIcons.dc1Icon(
                                      size: 18,
                                      color: c.status.displayColor,
                                    )
                                  : ConnectorIcons.dc2Icon(
                                      size: 18,
                                      color: c.status.displayColor,
                                    ))
                            : ConnectorIcons.acIcon(
                                size: 18,
                                color: c.status.displayColor,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.powerType == 'DC'
                                  ? 'DC-Konnektör ${c.id}'
                                  : 'AC Konnektör',
                              style: AppTheme.headingSmall.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: c.status.displayColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  c.status.displayText,
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Power and cost info
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.chargingColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.chargingColor.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Güç',
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${c.chargingData!.currentPower.toStringAsFixed(1)} kW",
                                style: TextStyle(
                                  color: AppTheme.chargingColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.warningColor.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tutar',
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${c.chargingData!.cost.toStringAsFixed(2)} ₺',
                                style: AppTheme.headingSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // User info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: AppTheme.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.userFullName ?? 'Bilinmiyor',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.directions_car_outlined,
                              color: AppTheme.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              c.userCarPlate ?? 'Plaka Yok',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with connector info and status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.status.displayColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: c.powerType == 'DC'
                            ? (c.id == 1
                                  ? ConnectorIcons.dc1Icon(
                                      size: 18,
                                      color: c.status.displayColor,
                                    )
                                  : ConnectorIcons.dc2Icon(
                                      size: 18,
                                      color: c.status.displayColor,
                                    ))
                            : ConnectorIcons.acIcon(
                                size: 18,
                                color: c.status.displayColor,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.powerType == 'DC'
                                  ? 'DC-Konnektör ${c.id}'
                                  : 'AC Konnektör',
                              style: AppTheme.headingSmall.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: c.status.displayColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  c.status.displayText,
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Arızalı cihazlarda hata bilgisini göster
                  if (c.status == ConnectorStatus.offline &&
                      c.errorInfo != null &&
                      c.errorInfo!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.errorColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hata Detayı',
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.errorColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c.errorInfo!,
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
