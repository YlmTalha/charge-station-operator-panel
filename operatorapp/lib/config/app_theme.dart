import 'package:flutter/material.dart';

class AppTheme {
  static bool _isDarkMode = false;

  static bool get isDarkMode => _isDarkMode;

  static void toggleTheme() {
    _isDarkMode = !_isDarkMode;
  }

  // ==================== LIGHT THEME COLORS - Clean & Modern ====================
  static const Color _lightPrimary = Color(
    0xFFF8FAFC,
  ); // Çok hafif mavi-gri (slate-50)
  static const Color _lightSecondary = Color(0xFFF1F5F9); // slate-100
  static const Color _lightCard = Color(0xFFFFFFFF); // Beyaz kartlar
  static const Color _lightSurface = Color(0xFFE2E8F0); // slate-200

  // ==================== DARK THEME COLORS - Premium Dark (Referans'tan ilham) ====================
  static const Color _darkPrimary = Color(
    0xFF0A0E1A,
  ); // Çok koyu (neutral-950 gibi)
  static const Color _darkSecondary = Color(0xFF1E293B); // neutral-900
  static const Color _darkCard = Color(0xFF1E293B); // neutral-900 (kartlar)
  static const Color _darkSurface = Color(0xFF1F2937); // neutral-800 (yüzeyler)

  // ==================== ACCENT COLORS - Referans'tan İlham (Emerald Primary) ====================
  static const Color primaryAccent = Color(
    0xFF10B981,
  ); // Emerald-500 (referans gibi)
  static const Color secondaryAccent = Color(0xFF059669); // Emerald-600

  // ==================== STATUS COLORS - Zengin Ama Profesyonel ====================
  static const Color successColor = Color(0xFF10B981); // Emerald - Başarı/Para
  static const Color warningColor = Color(0xFFF59E0B); // Amber - Dikkat/Uyarı
  static const Color errorColor = Color(0xFFEF4444); // Red - Hata/Arıza
  static const Color infoColor = Color(0xFF3B82F6); // Blue - Bilgi/İstatistik

  // Ekstra tonlar (güzel ve profesyonel)
  static const Color tealColor = Color(0xFF14B8A6); // Teal - Enerji/Teknoloji
  static const Color indigoColor = Color(0xFF6366F1); // Indigo - Premium
  static const Color cyanColor = Color(0xFF06B6D4); // Cyan - Aktif durum

  // ==================== CHARGING STATUS - Renkli & Anlamlı ====================
  static const Color chargingColor = Color(
    0xFF14B8A6,
  ); // Teal - Aktif şarj (enerji hissi)
  static const Color availableColor = Color(
    0xFF3B82F6,
  ); // Blue - Müsait (pozitif)
  static const Color offlineColor = Color(0xFFEF4444); // Red - Arızalı
  static const Color preparingColor = Color(0xFFF59E0B); // Amber - Hazırlanıyor
  static const Color finishingColor = Color(
    0xFF10B981,
  ); // Emerald - Tamamlanıyor

  // ==================== DYNAMIC COLORS (Tema'ya göre) ====================
  static Color get primaryDark => _isDarkMode ? _darkPrimary : _lightPrimary;
  static Color get secondaryDark =>
      _isDarkMode ? _darkSecondary : _lightSecondary;
  static Color get cardDark => _isDarkMode ? _darkCard : _lightCard;
  static Color get surfaceDark => _isDarkMode ? _darkSurface : _lightSurface;

  // Kart border rengi (minimalist ve ince)
  static Color get cardBorder => _isDarkMode
      ? const Color(0xFF374151) // Gray-700
      : const Color(0xFFE5E7EB); // Gray-200 (daha soft)

  // ==================== TEXT COLORS - Referans Benzeri ====================
  static Color get textPrimary => _isDarkMode
      ? const Color(0xFFF9FAFB)
      : const Color(0xFF111827); // Gray-50/900
  static Color get textSecondary => _isDarkMode
      ? const Color(0xFFD1D5DB)
      : const Color(0xFF6B7280); // Gray-300/500
  static Color get textTertiary => _isDarkMode
      ? const Color(0xFF9CA3AF)
      : const Color(0xFF9CA3AF); // Gray-400
  static Color get textMuted => _isDarkMode
      ? const Color(0xFF6B7280)
      : const Color(0xFFD1D5DB); // Gray-500/300

  // ==================== GRADIENTS - Zengin & Profesyonel ====================
  // Ana gradient - Teal (enerji ve teknoloji hissi)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Başarı gradient - Emerald tonları
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Fiyat gradient - Emerald (referans: para = yeşil)
  static LinearGradient get priceGradient => const LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)], // Her zaman emerald
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Uyarı gradient - Amber (daha soft)
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Hata gradient - Red (referans)
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Bilgi gradient - Blue (profesyonel)
  static const LinearGradient infoGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Teal gradient - Enerji/Teknoloji
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Indigo gradient - Premium vurgu
  static const LinearGradient indigoGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cyan gradient - Aktif durum
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get backgroundGradient => _isDarkMode
      ? const LinearGradient(
          colors: [Color(0xFF0A0E1A), Color(0xFF0F172A)], // Premium koyu
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
      : const LinearGradient(
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFEFF6FF),
          ], // Hafif mavi-beyaz (temiz)
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

  // ==================== TYPOGRAPHY ====================
  static TextStyle get headingLarge => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get headingMedium => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle get headingSmall => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textTertiary,
    height: 1.3,
  );

  static TextStyle get caption =>
      TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: textMuted);

  // ==================== SHADOWS - Premium & Soft ====================
  static List<BoxShadow> get cardShadow => _isDarkMode
      ? [
          const BoxShadow(
            color: Color(0x40000000),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ]
      : [
          const BoxShadow(
            color: Color(0x0A000000), // Daha soft
            blurRadius: 16,
            offset: Offset(0, 2),
            spreadRadius: -2,
          ),
          const BoxShadow(
            color: Color(0x05000000), // Çok hafif
            blurRadius: 8,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ];

  static List<BoxShadow> get elevatedShadow => _isDarkMode
      ? [
          const BoxShadow(
            color: Color(0x60000000),
            blurRadius: 24,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
        ]
      : [
          const BoxShadow(
            color: Color(0x0D000000), // Daha yumuşak
            blurRadius: 24,
            offset: Offset(0, 4),
            spreadRadius: -4,
          ),
          const BoxShadow(
            color: Color(0x08000000), // Hafif derinlik
            blurRadius: 12,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ];

  // Emerald glow (primary için) - Referans
  static const List<BoxShadow> glowShadow = [
    BoxShadow(
      color: Color(0x4010B981),
      blurRadius: 20,
      offset: Offset(0, 0),
      spreadRadius: 0,
    ),
  ];

  // Emerald glow (fiyat kartları)
  static const List<BoxShadow> priceGlowShadow = [
    BoxShadow(
      color: Color(0x6010B981),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  // Emerald glow (success/charging için)
  static const List<BoxShadow> successGlowShadow = [
    BoxShadow(
      color: Color(0x6010B981),
      blurRadius: 20,
      offset: Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  // Amber glow (warning için) - Daha soft
  static const List<BoxShadow> warningGlowShadow = [
    BoxShadow(
      color: Color(0x60F59E0B),
      blurRadius: 20,
      offset: Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  // Red glow (error için)
  static const List<BoxShadow> errorGlowShadow = [
    BoxShadow(
      color: Color(0x60EF4444),
      blurRadius: 20,
      offset: Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  // Blue glow (info için)
  static const List<BoxShadow> infoGlowShadow = [
    BoxShadow(
      color: Color(0x603B82F6),
      blurRadius: 20,
      offset: Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  // Teal glow (enerji için)
  static const List<BoxShadow> tealGlowShadow = [
    BoxShadow(
      color: Color(0x6014B8A6),
      blurRadius: 20,
      offset: Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  // Indigo glow (premium için)
  static const List<BoxShadow> indigoGlowShadow = [
    BoxShadow(
      color: Color(0x606366F1),
      blurRadius: 20,
      offset: Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  // ==================== BORDER RADIUS ====================
  static const double radiusSmall = 10.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 18.0;
  static const double radiusXLarge = 24.0;
}
