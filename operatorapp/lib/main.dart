import 'dart:io';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

// Animasyonsuz sayfa geçişi için özel builder
class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const EVChargerApp());
}

class EVChargerApp extends StatelessWidget {
  const EVChargerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EV Şarj İzleme',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        primaryColor: const Color(0xFF14B8A6),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Light background
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF14B8A6),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF14B8A6)),
        ),
        // Sayfa geçiş animasyonlarını kaldır
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF14B8A6),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Dark background
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF14B8A6),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF14B8A6)),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: ThemeMode.system, // Sistem ayarını takip et
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authService = AuthService();
      bool isValid = await authService.isTokenValid();

      // Token geçersizse otomatik giriş dene
      if (!isValid) {
        debugPrint('Token geçersiz, otomatik giriş deneniyor...');
        final autoLoginToken = await authService.tryAutoRelogin();
        if (autoLoginToken != null) {
          debugPrint('Otomatik giriş başarılı');
          isValid = true;
        } else {
          debugPrint('Otomatik giriş başarısız');
        }
      }

      if (mounted) {
        setState(() {
          _isLoggedIn = isValid;
          _isLoading = false;
        });
      }

      debugPrint('Auth durumu kontrol edildi: $_isLoggedIn');
    } catch (e) {
      debugPrint('Auth kontrol hatası: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
        ),
      );
    }

    return _isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
