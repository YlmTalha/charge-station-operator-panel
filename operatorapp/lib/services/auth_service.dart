import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'bearer_token';
  static const _lastEmailKey = 'last_email';
  static const _savedEmailKey = 'saved_email';
  static const _savedPasswordKey = 'saved_password';
  static const _autoLoginEnabledKey = 'auto_login_enabled';

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        debugPrint('Token mevcut ve geçerli');
        return token;
      }
      debugPrint('Token bulunamadı veya boş');
      return null;
    } catch (e) {
      debugPrint('Token okuma hatası: $e');
      return null;
    }
  }

  Future<String?> getLastEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastEmail = prefs.getString(_lastEmailKey);
      debugPrint('Son kaydedilen email: $lastEmail');
      return lastEmail;
    } catch (e) {
      debugPrint('Son email okuma hatası: $e');
      return null;
    }
  }

  Future<void> saveLastEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastEmailKey, email);
      debugPrint('Email kaydedildi: $email');
    } catch (e) {
      debugPrint('Email kaydetme hatası: $e');
    }
  }

  // Otomatik giriş için kullanıcı bilgilerini güvenli şekilde kaydet
  Future<void> saveCredentialsForAutoLogin(
    String email,
    String password,
  ) async {
    try {
      await _storage.write(key: _savedEmailKey, value: email);
      await _storage.write(key: _savedPasswordKey, value: password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoLoginEnabledKey, true);

      debugPrint('Kullanıcı bilgileri otomatik giriş için kaydedildi');
    } catch (e) {
      debugPrint('Kullanıcı bilgilerini kaydetme hatası: $e');
    }
  }

  // Kaydedilmiş kullanıcı bilgilerini al
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoLoginEnabled = prefs.getBool(_autoLoginEnabledKey) ?? false;

      if (!autoLoginEnabled) {
        debugPrint('Otomatik giriş etkin değil');
        return null;
      }

      final email = await _storage.read(key: _savedEmailKey);
      final password = await _storage.read(key: _savedPasswordKey);

      if (email != null &&
          password != null &&
          email.isNotEmpty &&
          password.isNotEmpty) {
        debugPrint('Kaydedilmiş kullanıcı bilgileri bulundu');
        return {'email': email, 'password': password};
      }

      debugPrint('Kaydedilmiş kullanıcı bilgileri bulunamadı');
      return null;
    } catch (e) {
      debugPrint('Kaydedilmiş kullanıcı bilgilerini alma hatası: $e');
      return null;
    }
  }

  // Otomatik giriş ayarını kontrol et
  Future<bool> isAutoLoginEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoLoginEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Otomatik giriş ayarını kontrol etme hatası: $e');
      return false;
    }
  }

  // Token süresi dolduğunda otomatik yeniden giriş yap
  Future<String?> tryAutoRelogin() async {
    try {
      debugPrint('Otomatik yeniden giriş deneniyor...');

      final credentials = await getSavedCredentials();
      if (credentials == null) {
        debugPrint(
          'Kaydedilmiş kullanıcı bilgileri yok, otomatik giriş yapılamıyor',
        );
        return null;
      }

      final email = credentials['email']!;
      final password = credentials['password']!;

      debugPrint('Kaydedilmiş bilgilerle yeniden giriş yapılıyor: $email');
      return await loginWithCredentials(email, password);
    } catch (e) {
      debugPrint('Otomatik yeniden giriş hatası: $e');
      return null;
    }
  }

  // Token'ın gerçekten geçerli olup olmadığını API'ye sorarak kontrol et
  Future<bool> isTokenValid() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        debugPrint('Token yok, geçersiz');
        return false;
      }

      // API'ye basit bir test isteği gönder (örneğin charging stations)
      final uri = Uri.parse('${ApiConfig.stationsUrl}?Issuer=true&Limit=1');
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Token doğrulama isteği zaman aşımına uğradı');
              return http.Response('Timeout', 408);
            },
          );

      if (response.statusCode == 200) {
        debugPrint('Token geçerli (API yanıt: 200)');
        return true;
      } else if (response.statusCode == 401) {
        debugPrint('Token geçersiz veya süresi dolmuş (401)');
        return false;
      } else {
        debugPrint('Token doğrulama belirsiz: ${response.statusCode}');
        // Diğer hata kodlarında token var kabul et (ağ sorunu olabilir)
        return true;
      }
    } catch (e) {
      debugPrint('Token doğrulama hatası: $e');
      // Hata durumunda token varsa geçerli kabul et
      final token = await getToken();
      return token != null && token.isNotEmpty;
    }
  }

  Future<String?> loginWithCredentials(
    String email,
    String password, {
    bool saveForAutoLogin = false,
  }) async {
    try {
      debugPrint('Kullanıcı kimlik bilgileriyle giriş yapılıyor...');
      final uri = Uri.parse(ApiConfig.loginUrl);
      final body = jsonEncode({
        'email': email,
        'password': password,
        'acceptEula': true,
        'tenant': ApiConfig.tenant,
      });

      debugPrint('Login API çağrısı: ${uri.toString()}');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      debugPrint('Login yanıt kodu: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final token = decoded['token'] as String?;
        if (token != null) {
          await _storage.write(key: _tokenKey, value: token);
          await saveLastEmail(email); // Son kullanılan email'i kaydet

          // Otomatik giriş için bilgileri kaydet
          if (saveForAutoLogin) {
            await saveCredentialsForAutoLogin(email, password);
          }

          debugPrint('Token başarıyla alındı ve kaydedildi');
          return token;
        } else {
          debugPrint('API yanıtında token bulunamadı: ${response.body}');
          throw Exception('API\'den token alınamadı.');
        }
      } else {
        debugPrint('Login hatası: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 401) {
          throw Exception('Kullanıcı adı veya şifre yanlış.');
        } else if (response.statusCode == 403) {
          throw Exception('Bu hesapla giriş yapma yetkiniz yok.');
        } else if (response.statusCode >= 500) {
          throw Exception('Sunucu hatası. Lütfen daha sonra tekrar deneyin.');
        } else {
          throw Exception('Giriş başarısız: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Login sırasında hata: $e');
      if (e.toString().contains('Kullanıcı adı') ||
          e.toString().contains('Bu hesapla') ||
          e.toString().contains('Sunucu hatası') ||
          e.toString().contains('Giriş başarısız')) {
        rethrow;
      }
      throw Exception('Ağ bağlantısı hatası: $e');
    }
  }

  Future<void> logout({bool clearSavedCredentials = false}) async {
    try {
      await _storage.delete(key: _tokenKey);

      if (clearSavedCredentials) {
        await _storage.delete(key: _savedEmailKey);
        await _storage.delete(key: _savedPasswordKey);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_autoLoginEnabledKey, false);
        debugPrint('Çıkış yapıldı, kaydedilmiş bilgiler de silindi');
      } else {
        debugPrint('Çıkış yapıldı, kaydedilmiş bilgiler korundu');
      }
    } catch (e) {
      debugPrint('Logout hatası: $e');
      // Hata olsa bile devam et
    }
  }

  static Future<void> clearAllData() async {
    try {
      const storage = FlutterSecureStorage();
      await storage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // SharedPreferences'ı da temizle
      debugPrint('Tüm uygulama verileri temizlendi');
    } catch (e) {
      debugPrint('Veri temizleme hatası: $e');
    }
  }
}
