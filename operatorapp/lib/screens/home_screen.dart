import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_theme.dart';
import '../data/station_repository.dart';
import '../models/charging_station.dart';
import '../models/connector.dart';
import '../widgets/error_display_widget.dart';
import '../services/auth_service.dart';
import 'tabs/live_tab.dart';
import 'tabs/active_tab.dart';
import 'tabs/history_tab.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _favoriteStationSerials = [
    'AS03400001',
    'AS03400011',
    'SRM00600001',
    'SRM00600002',
    'SRM00600003',
    'SRM00600004',
    'SRM00600005',
    'SRM02000001',
    'SRM02700001',
    'SRM03400001',
    'SRM03400002',
    'SRM03400004',
    'SRM03400005',
    'SRM03400006',
    'SRM03400007',
    'SRM03400008',
    'SRM03400009',
    'SRM03400014',
    'SRM03400015',
    'SRM03400016',
    'SRM03400017',
    'SRM03400018',
    'SRM03400019',
    'SRM03400020',
    'SRM03400021',
    'SRM03400022',
    'SRM03400026',
    'SRM03700001',
    'SRM03700002',
    'SRM04100001',
    'SRM05000001',
    'SRM05400001',
    'SRM05400002',
    'SRM05400003',
    'SRM05400004',
    'SRM05400005',
    'SRM05400006',
    'SRM05400007',
    'SRM05400008',
    'SRM05400009',
    'SRM05400010',
    'SRM05400014',
    'SRM05400017',
    'SRM05400018',
    'SRM05400019',
    'SRM05500001',
    'SRM05500002',
    'SRM05500005',
    'SRM05500006',
    'SRM05500007',
    'SRM05500008',
    'SRM05700001',
    'SRM05700002',
    'SRM05800001',
    'SRM05800002',
    'SRM05800004',
  ];

  String _activeTab = 'live';
  late Timer _timer;
  late PageController _pageController;
  int _currentPageIndex = 0;
  final List<String> _tabKeys = ['live', 'active', 'history'];

  // Scroll controllers for each tab
  final ScrollController _liveScrollController = ScrollController();
  final ScrollController _activeScrollController = ScrollController();
  final ScrollController _historyScrollController = ScrollController();

  bool _isLiveLoading = true;
  String? _liveError;
  List<ChargingStation> _liveStations = [];

  final GlobalKey<HistoryTabState> _historyTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) => _refreshCurrentTab(),
    );
    _loadLiveData();
  }

  void _refreshCurrentTab() {
    if (_activeTab == 'live' || _activeTab == 'active') {
      _loadLiveData(isRefresh: false);
    } else if (_activeTab == 'history') {
      _historyTabKey.currentState?.refreshData();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _liveScrollController.dispose();
    _activeScrollController.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLiveData({bool isRefresh = true}) async {
    if (isRefresh) {
      setState(() {
        _isLiveLoading = true;
        _liveError = null;
      });
    }
    try {
      final stations = await StationRepository.fetchLiveStations();
      if (mounted) {
        setState(() {
          _liveStations = stations
              .where((s) => _favoriteStationSerials.contains(s.serial))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Anlık veri yükleme hatası: $e');
      if (mounted) {
        setState(() => _liveError = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLiveLoading = false);
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
      _activeTab = _tabKeys[index];
    });
    _refreshCurrentTab();
  }

  void _onTabTapped(String tabKey) {
    final index = _tabKeys.indexOf(tabKey);
    if (index != -1) {
      // Eğer aynı tab'a tıklanırsa yukarı scroll et ve refresh yap
      if (_currentPageIndex == index) {
        _scrollToTopAndRefresh(tabKey);
      } else {
        // Farklı tab'a geç (animasyonsuz)
        _pageController.jumpToPage(index);
      }
    }
  }

  Future<void> _scrollToTopAndRefresh(String tabKey) async {
    ScrollController? controller;

    switch (tabKey) {
      case 'live':
        controller = _liveScrollController;
        break;
      case 'active':
        controller = _activeScrollController;
        break;
      case 'history':
        controller = _historyScrollController;
        break;
    }

    if (controller != null && controller.hasClients) {
      // Yukarı scroll et (animasyonsuz)
      controller.jumpTo(0);
    }

    // Sonra refresh yap
    switch (tabKey) {
      case 'live':
      case 'active':
        await _loadLiveData();
        break;
      case 'history':
        await _historyTabKey.currentState?.refreshData();
        break;
    }
  }

  List<Connector> get _activeConnectors => _liveStations
      .expand((s) => s.connectors)
      .where(
        (c) =>
            c.status == ConnectorStatus.charging ||
            c.status == ConnectorStatus.starting,
      )
      .toList();

  Future<void> _logout() async {
    try {
      // Logout işlemini başlat
      debugPrint('Çıkış işlemi başlatılıyor...');

      final authService = AuthService();
      await authService.logout();

      // Tüm secure storage'ı temizle
      await AuthService.clearAllData();

      // Navigator kontrol et ve login sayfasına yönlendir
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        debugPrint('Login sayfasına yönlendirildi');
      }
    } catch (e) {
      debugPrint('Çıkış hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış hatası: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Açık tema için koyu iconlar
        systemNavigationBarColor: AppTheme.primaryDark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: Column(
            children: [
              _buildModernHeader(),
              _buildModernTabBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const ClampingScrollPhysics(), // Elle kaydırma aktif
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: _buildLiveTab(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: _buildActiveTab(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: _buildHistoryTab(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          border: Border(
            bottom: BorderSide(
              color: AppTheme.isDarkMode
                  ? AppTheme.surfaceDark
                  : const Color(0xFFE5E7EB), // Light: açık border
              width: 1,
            ),
          ),
          boxShadow: AppTheme.isDarkMode
              ? null
              : [
                  // Light mode'da hafif shadow
                  const BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Modern app branding
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusLarge,
                        ),
                        boxShadow: AppTheme.isDarkMode
                            ? AppTheme.glowShadow
                            : [
                                // Light mode: daha soft shadow
                                BoxShadow(
                                  color: AppTheme.primaryAccent.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.ev_station_rounded,
                        color:
                            Colors.white, // Her zaman beyaz (gradient üzerinde)
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Şarj Mahal',
                          style: AppTheme.headingLarge.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'EV Şarj İstasyonu Yönetimi',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Enhanced station counter with theme toggle and logout
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.successGradient,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusLarge,
                        ),
                        boxShadow: AppTheme.successGlowShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.flash_on_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_liveStations.length}',
                            style: AppTheme.headingMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Theme toggle button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          AppTheme.toggleTheme();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppTheme.isDarkMode
                                ? [
                                    const Color(
                                      0xFFF59E0B,
                                    ), // Amber (daha soft)
                                    const Color(0xFFD97706),
                                  ]
                                : [
                                    const Color(
                                      0xFF6B7280,
                                    ), // Gray (minimalist)
                                    const Color(0xFF4B5563),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLarge,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (AppTheme.isDarkMode
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFF6B7280))
                                      .withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          AppTheme.isDarkMode
                              ? Icons.wb_sunny_rounded
                              : Icons.nightlight_round,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Logout button
                    GestureDetector(
                      onTap: _logout,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.errorColor,
                              AppTheme.errorColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLarge,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.errorColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceDark, width: 1),
      ),
      child: Row(
        children: [
          _buildModernTabItem('live', 'Anlık', Icons.wifi_rounded, 0),
          _buildModernTabItem(
            'active',
            'Aktif',
            Icons.flash_on_rounded,
            1,
            badgeCount: _activeConnectors.length,
          ),
          _buildModernTabItem('history', 'Geçmiş', Icons.history_rounded, 2),
        ],
      ),
    );
  }

  Widget _buildModernTabItem(
    String key,
    String title,
    IconData icon,
    int index, {
    int badgeCount = 0,
  }) {
    final isActive = _currentPageIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isActive ? Colors.white : AppTheme.textTertiary,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.textTertiary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -6,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.errorGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.errorColor.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveTab() {
    if (_isLiveLoading) {
      return _buildLoadingState(
        color: AppTheme.primaryAccent,
        message: 'Anlık veriler yükleniyor...',
        icon: Icons.wifi_rounded,
      );
    }
    if (_liveError != null) {
      return ErrorDisplayWidget(
        error: _liveError!,
        onRetry: _loadLiveData,
        icon: Icons.wifi_off,
      );
    }
    return RefreshIndicator(
      onRefresh: () async => await _loadLiveData(),
      color: AppTheme.primaryAccent,
      backgroundColor: AppTheme.cardDark,
      strokeWidth: 3.0,
      child: LiveTab(
        stations: _liveStations,
        scrollController: _liveScrollController,
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_isLiveLoading) {
      return _buildLoadingState(
        color: AppTheme.chargingColor,
        message: 'Aktif şarj verileri yükleniyor...',
        icon: Icons.flash_on_rounded,
      );
    }
    if (_liveError != null) {
      return ErrorDisplayWidget(
        error: _liveError!,
        onRetry: _loadLiveData,
        icon: Icons.flash_off,
      );
    }
    return RefreshIndicator(
      onRefresh: () async => await _loadLiveData(),
      color: AppTheme.chargingColor,
      backgroundColor: AppTheme.cardDark,
      strokeWidth: 3.0,
      child: ActiveTab(
        activeConnectors: _activeConnectors,
        liveStations: _liveStations,
        scrollController: _activeScrollController,
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _historyTabKey.currentState?.refreshData();
      },
      color: AppTheme.warningColor,
      backgroundColor: AppTheme.cardDark,
      strokeWidth: 3.0,
      child: HistoryTab(
        key: _historyTabKey,
        scrollController: _historyScrollController,
      ),
    );
  }

  Widget _buildLoadingState({
    required Color color,
    required String message,
    required IconData icon,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 32),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.6)],
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
            message,
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
}
