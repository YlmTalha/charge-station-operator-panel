import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class ApiHelper {
  static final AuthService _authService = AuthService();

  /// API çağrısı yapar ve 401 hatası durumunda otomatik yeniden giriş dener
  static Future<http.Response> makeAuthorizedRequest({
    required Uri uri,
    String method = 'GET',
    Map<String, String>? headers,
    String? body,
    int maxRetries = 1,
  }) async {
    String? token = await _authService.getToken();

    // Token bulunamazsa otomatik giriş dene
    if (token == null) {
      debugPrint('Token bulunamadı, otomatik giriş deneniyor...');
      token = await _authService.tryAutoRelogin();

      if (token == null) {
        throw Exception('Token bulunamadı. Lütfen giriş yapın.');
      }
    }

    final requestHeaders = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      ...?headers,
    };

    debugPrint('API çağrısı: ${method.toUpperCase()} ${uri.toString()}');

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(uri, headers: requestHeaders, body: body);
          break;
        case 'PUT':
          response = await http.put(uri, headers: requestHeaders, body: body);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: requestHeaders);
          break;
        default:
          throw Exception('Desteklenmeyen HTTP metodu: $method');
      }
    } catch (e) {
      debugPrint('API çağrısı ağ hatası: $e');
      throw Exception('Ağ bağlantısı hatası: $e');
    }

    debugPrint('API yanıt kodu: ${response.statusCode}');

    // 401 hatası alındığında otomatik yeniden giriş dene
    if (response.statusCode == 401 && maxRetries > 0) {
      debugPrint('401 hatası alındı, otomatik yeniden giriş deneniyor...');

      try {
        final newToken = await _authService.tryAutoRelogin();
        if (newToken != null) {
          debugPrint(
            'Otomatik yeniden giriş başarılı, API çağrısı tekrarlanıyor...',
          );

          // Yeni token ile tekrar dene
          return await makeAuthorizedRequest(
            uri: uri,
            method: method,
            headers: headers,
            body: body,
            maxRetries: maxRetries - 1,
          );
        } else {
          debugPrint('Otomatik yeniden giriş başarısız');
          throw Exception('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
        }
      } catch (autoLoginError) {
        debugPrint('Otomatik yeniden giriş hatası: $autoLoginError');
        throw Exception('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
      }
    }

    // Başarılı yanıt kontrolü
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response;
    }

    // Diğer hata durumları
    debugPrint('API hatası: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 401) {
      throw Exception('Yetkisiz erişim. Lütfen tekrar giriş yapın.');
    } else if (response.statusCode == 403) {
      throw Exception('Yetkisiz erişim. Lütfen yöneticinize başvurun.');
    } else if (response.statusCode == 404) {
      throw Exception('API endpoint bulunamadı.');
    } else if (response.statusCode >= 500) {
      throw Exception('Sunucu hatası. Lütfen daha sonra tekrar deneyin.');
    } else {
      throw Exception(
        'API Hatası: ${response.statusCode} - ${response.reasonPhrase}',
      );
    }
  }

  /// GET request wrapper
  static Future<http.Response> get(Uri uri, {Map<String, String>? headers}) {
    return makeAuthorizedRequest(uri: uri, method: 'GET', headers: headers);
  }

  /// POST request wrapper
  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) {
    return makeAuthorizedRequest(
      uri: uri,
      method: 'POST',
      headers: headers,
      body: body,
    );
  }

  /// PUT request wrapper
  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) {
    return makeAuthorizedRequest(
      uri: uri,
      method: 'PUT',
      headers: headers,
      body: body,
    );
  }

  /// DELETE request wrapper
  static Future<http.Response> delete(Uri uri, {Map<String, String>? headers}) {
    return makeAuthorizedRequest(uri: uri, method: 'DELETE', headers: headers);
  }
}
