import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../data/station_repository.dart';
import '../../models/charging_history.dart';
import '../../models/history_stats.dart';
import '../../widgets/error_display_widget.dart';

class HistoryTab extends StatefulWidget {
  final ScrollController? scrollController;
  const HistoryTab({super.key, this.scrollController});
  @override
  State<HistoryTab> createState() => HistoryTabState();
}

class HistoryTabState extends State<HistoryTab> {
  bool _isHistoryLoading = true;
  bool _isMoreHistoryLoading = false;
  String? _historyError;
  List<ChargingHistory> _chargingHistory = [];
  HistoryStats _historyStats = HistoryStats();
  bool _canLoadMoreHistory = true;
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPowerType = 'all'; // 'all', 'AC', 'DC'

  @override
  void initState() {
    super.initState();
    _setDefaultDates();
    refreshData();
  }

  void _setDefaultDates() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, 1, 1, 00, 00, 00);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  Future<void> refreshData() async => await _loadHistoryData();

  Future<void> _loadHistoryData({bool loadMore = false}) async {
    if (_isMoreHistoryLoading) return;
    if (loadMore) {
      setState(() => _isMoreHistoryLoading = true);
    } else {
      if (mounted) {
        setState(() {
          _isHistoryLoading = true;
          _historyError = null;
        });
      }
    }

    try {
      final result = await StationRepository.fetchHistoryAndStats(
        startDate: _startDate,
        endDate: _endDate,
        skip: loadMore ? _chargingHistory.length : 0,
      );
      final newHistory = result['history'] as List<ChargingHistory>;
      final apiStats = result['stats'] as HistoryStats;

      if (mounted) {
        setState(() {
          if (loadMore) {
            _chargingHistory.addAll(newHistory);
          } else {
            _chargingHistory = newHistory;
          }
          _historyStats = apiStats;
          _canLoadMoreHistory = newHistory.length == 50;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _historyError = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isHistoryLoading = false;
          _isMoreHistoryLoading = false;
        });
      }
    }
  }

  /// AC veya DC filtresi seçildiğinde çağrılır
  Future<void> _loadFilteredData() async {
    if (mounted) {
      setState(() {
        _isHistoryLoading = true;
        _historyError = null;
      });
    }
    try {
      final result = await StationRepository.fetchFilteredStats(
        startDate: _startDate,
        endDate: _endDate,
        powerType: _selectedPowerType,
      );
      if (mounted) {
        setState(() {
          _chargingHistory = result['history'] as List<ChargingHistory>;
          _historyStats = result['stats'] as HistoryStats;
          _canLoadMoreHistory = false; // Filtrelenmiş veride sayfalama yok
        });
      }
    } catch (e) {
      if (mounted) setState(() => _historyError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isHistoryLoading = false);
      }
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (newDateRange != null) {
      setState(() {
        _startDate = newDateRange.start;
        _endDate = DateTime(
          newDateRange.end.year,
          newDateRange.end.month,
          newDateRange.end.day,
          23,
          59,
          59,
        );
      });
      _loadHistoryData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isHistoryLoading) {
      return _buildModernLoading();
    }
    if (_historyError != null) {
      return ErrorDisplayWidget(
        error: _historyError!,
        onRetry: () => _loadHistoryData(),
        icon: Icons.history_outlined,
      );
    }

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildExpandedStatsCard(),
              const SizedBox(height: 24),
              _buildHistoryFilter(),
              const SizedBox(height: 16),
              _buildPowerTypeFilter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
        _chargingHistory.isEmpty
            ? SliverToBoxAdapter(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.warningColor.withOpacity(0.1),
                                AppTheme.warningColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.warningColor.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            size: 64,
                            color: AppTheme.warningColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Kayıt bulunamadı",
                          style: AppTheme.headingMedium.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: Text(
                            "Seçilen tarih aralığında şarj işlemi yok",
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == _chargingHistory.length) {
                    if (_canLoadMoreHistory && !_isMoreHistoryLoading) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _loadHistoryData(loadMore: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.cardDark,
                              foregroundColor: AppTheme.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                                side: BorderSide(
                                  color: AppTheme.primaryAccent.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.expand_more_rounded,
                                  color: AppTheme.primaryAccent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Daha Fazla Yükle",
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else if (_isMoreHistoryLoading) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                            ),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryAccent,
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                  return _buildHistoryCard(_chargingHistory[index]);
                }, childCount: _chargingHistory.length + 1),
              ),
      ],
    );
  }

  Widget _buildModernLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.warningColor.withOpacity(0.2),
                  AppTheme.warningColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.warningColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warningColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.history_rounded,
              size: 40,
              color: AppTheme.warningColor,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.warningColor,
                  AppTheme.warningColor.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Geçmiş veriler yükleniyor...',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryFilter() {
    final f = DateFormat('dd.MM.yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.cardDark, AppTheme.cardDark.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.2)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.warningColor,
                      AppTheme.warningColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _startDate == null || _endDate == null
                      ? 'Tüm zamanlar'
                      : '${f.format(_startDate!)} - ${f.format(_endDate!)}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_calendar_rounded,
                  color: AppTheme.primaryAccent,
                  size: 20,
                ),
                onPressed: () => _selectDateRange(context),
              ),
              if (_startDate != null || _endDate != null)
                IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    _loadHistoryData();
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildDateShortcuts(),
      ],
    );
  }

  Widget _buildPowerTypeFilter() {
    return Row(
      children: [
        _buildPowerTypeButton('all', 'Tümü', Icons.electric_bolt_rounded),
        const SizedBox(width: 10),
        _buildPowerTypeButton('AC', 'AC', Icons.power_rounded),
        const SizedBox(width: 10),
        _buildPowerTypeButton('DC', 'DC', Icons.flash_on_rounded),
      ],
    );
  }

  Widget _buildPowerTypeButton(String value, String label, IconData icon) {
    final isSelected = _selectedPowerType == value;
    final Color activeColor = value == 'DC'
        ? AppTheme.chargingColor
        : value == 'AC'
            ? AppTheme.warningColor
            : AppTheme.primaryAccent;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedPowerType != value) {
            setState(() => _selectedPowerType = value);
            if (value == 'all') {
              _loadHistoryData();
            } else {
              _loadFilteredData();
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [activeColor, activeColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: isSelected
                  ? activeColor.withOpacity(0.6)
                  : AppTheme.primaryAccent.withOpacity(0.2),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textTertiary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateShortcuts() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildShortcutButton(
            'Bugün',
            Icons.today_rounded,
            () => _setQuickDate(0),
          ),
          const SizedBox(width: 12),
          _buildShortcutButton(
            'Dün',
            Icons.history_rounded,
            () => _setQuickDate(1),
          ),
          const SizedBox(width: 12),
          _buildShortcutButton(
            'Bu Hafta',
            Icons.date_range_rounded,
            () => _setQuickDate(7),
          ),
          const SizedBox(width: 12),
          _buildShortcutButton(
            'Bu Ay',
            Icons.calendar_month_rounded,
            () => _setQuickDate(30),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.surfaceDark,
              AppTheme.surfaceDark.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryAccent),
            const SizedBox(width: 8),
            Text(
              text,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setQuickDate(int daysBack) {
    final now = DateTime.now();
    late DateTime startDate;
    late DateTime endDate;

    switch (daysBack) {
      case 0: // Bugün
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 1: // Dün
        final yesterday = now.subtract(const Duration(days: 1));
        startDate = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          0,
          0,
          0,
        );
        endDate = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          23,
          59,
          59,
        );
        break;
      case 7: // Bu hafta
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
          0,
          0,
          0,
        );
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 30: // Bu ay
        startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }

    setState(() {
      _startDate = startDate;
      _endDate = endDate;
    });
    _loadHistoryData();
  }

  Widget _buildExpandedStatsCard() {
    final bool isFiltered = _selectedPowerType != 'all';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.cardDark, AppTheme.surfaceDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.elevatedShadow,
        border: Border.all(
          color: AppTheme.primaryAccent.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.priceGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: AppTheme.priceGlowShadow,
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _startDate == null || _endDate == null
                          ? 'Tüm Zamanlar Özet'
                          : 'Seçilen Dönem Özet',
                      style: AppTheme.headingMedium.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _startDate == null || _endDate == null
                          ? 'Toplam veriler'
                          : '${DateFormat('dd.MM.yyyy').format(_startDate!)} - ${DateFormat('dd.MM.yyyy').format(_endDate!)}',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textTertiary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Toplam Kazanç - Üstte tek
          _buildMainStatCard(
            icon: Icons.account_balance_wallet,
            label: isFiltered ? '$_selectedPowerType Kazanç' : 'Toplam Kazanç',
            value: _formatCurrency(_historyStats.totalPrice),
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 16),
          // Tüketim ve Oturum - Yan yana
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  icon: Icons.electric_bolt,
                  label: isFiltered ? '$_selectedPowerType Tüketim' : 'Tüketim',
                  value:
                      '${_formatNumber(_historyStats.totalConsumptionKWh, 1)} kWh',
                  color: AppTheme.chargingColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard(
                  icon: Icons.receipt_long,
                  label: isFiltered ? '$_selectedPowerType Oturum' : 'Oturum',
                  value: '${_historyStats.count}',
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    return '${formatter.format(amount).replaceAll('.', ',')} ₺';
  }

  String _formatNumber(double number, int decimals) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'tr_TR');
    return formatter.format(number).replaceAll('.', ',');
  }

  Widget _buildMainStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    // Success için emerald gradient seç
    final gradient = color == AppTheme.successColor
        ? AppTheme.successGradient
        : LinearGradient(colors: [color, color.withOpacity(0.8)]);

    final glow = color == AppTheme.successColor
        ? AppTheme.successGlowShadow
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
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    // Charging için teal, Info için blue gradient
    final gradient = color == AppTheme.chargingColor
        ? AppTheme.tealGradient
        : AppTheme.infoGradient;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ChargingHistory session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.cardBorder.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          // Header with date and station
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.date,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.timeRange,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        session.station.length > 20
                            ? '${session.station.substring(0, 20)}...'
                            : session.station,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.srmNumber,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // User info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        session.user.isEmpty ? 'Bilinmiyor' : session.user,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats grid
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeStatItem(
                        value: session.formattedDuration,
                        color: AppTheme.infoColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildConsumptionStatItem(
                        value: "${session.energy.toStringAsFixed(1)} kWh",
                        color: AppTheme.chargingColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Price highlight
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.priceGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.priceGlowShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.currency_lira,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${session.cost.toStringAsFixed(2)} TL',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
  }

  Widget _buildTimeStatItem({required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: color, size: 18),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionStatItem({
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.battery_charging_full, color: color, size: 18),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
