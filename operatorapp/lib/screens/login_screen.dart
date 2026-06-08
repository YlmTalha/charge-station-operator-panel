import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLastEmailAndCheckAutoLogin(); // Son kullanılan email'i yükle ve otomatik giriş kontrol et
  }

  Future<void> _loadLastEmailAndCheckAutoLogin() async {
    try {
      final authService = AuthService();

      // Otomatik giriş kontrol et
      final autoLoginEnabled = await authService.isAutoLoginEnabled();
      if (autoLoginEnabled) {
        final credentials = await authService.getSavedCredentials();
        if (credentials != null) {
          setState(() {
            _emailController.text = credentials['email']!;
            _passwordController.text = credentials['password']!;
            _rememberMe = true;
          });
          debugPrint('Kaydedilmiş kullanıcı bilgileri yüklendi');
          return;
        }
      }

      // Otomatik giriş yoksa sadece son email'i yükle
      final lastEmail = await authService.getLastEmail();
      if (lastEmail != null && lastEmail.isNotEmpty) {
        setState(() {
          _emailController.text = lastEmail;
        });
        debugPrint('Son kullanılan email yüklendi: $lastEmail');
      }
    } catch (e) {
      debugPrint('Kullanıcı bilgilerini yükleme hatası: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      final token = await authService.loginWithCredentials(
        _emailController.text.trim(),
        _passwordController.text,
        saveForAutoLogin: _rememberMe, // Beni hatırla seçeneği
      );

      if (token != null && mounted) {
        // Login başarılı, ana sayfaya yönlendir (animasyonsuz)
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Giriş başarısız. Lütfen bilgilerinizi kontrol edin.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Giriş hatası: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.primaryDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo ve başlık
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLarge,
                          ),
                          boxShadow: AppTheme.glowShadow,
                        ),
                        child: Icon(
                          Icons.ev_station_rounded,
                          color: AppTheme.primaryDark,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Şarj Mahal',
                        style: AppTheme.headingLarge.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'EV Şarj İstasyonu Yönetimi',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textTertiary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Login formu
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLarge,
                          ),
                          border: Border.all(
                            color: AppTheme.primaryAccent.withOpacity(0.2),
                          ),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Giriş Yap',
                              style: AppTheme.headingMedium.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'E-posta',
                                labelStyle: TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                                hintText: 'ornek@email.com',
                                hintStyle: TextStyle(
                                  color: AppTheme.textTertiary,
                                ),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.primaryAccent,
                                ),
                                filled: true,
                                fillColor: AppTheme.surfaceDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryAccent.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryAccent.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryAccent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'E-posta adresi gerekli';
                                }
                                if (!value.contains('@')) {
                                  return 'Geçerli bir e-posta adresi girin';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Şifre',
                                labelStyle: TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                                hintText: 'Şifrenizi girin',
                                hintStyle: TextStyle(
                                  color: AppTheme.textTertiary,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outlined,
                                  color: AppTheme.primaryAccent,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: AppTheme.surfaceDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryAccent.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryAccent.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppTheme.primaryAccent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Şifre gerekli';
                                }
                                if (value.length < 6) {
                                  return 'Şifre en az 6 karakter olmalı';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Beni Hatırla checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: AppTheme.primaryAccent,
                                  checkColor: AppTheme.primaryDark,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    child: Text(
                                      'Beni hatırla (otomatik giriş)',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Error message
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                  border: Border.all(
                                    color: AppTheme.errorColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: AppTheme.errorColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: AppTheme.errorColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Login button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryAccent,
                                foregroundColor: AppTheme.primaryDark,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppTheme.primaryDark,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Giriş yapılıyor...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'Giriş Yap',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Alt bilgi
                      Text(
                        'Giriş yaparak hizmet şartlarımızı kabul etmiş olursunuz.',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
