// ---------------------------------------------------------------------------
// ÖRNEK YAPILANDIRMA DOSYASI
//
// Bu dosyayı `api_config.dart` adıyla kopyalayın ve aşağıdaki değerleri kendi
// backend/sunucu bilgilerinizle güncelleyin. Gerçek `api_config.dart` dosyası
// `.gitignore` ile takip dışı bırakılmıştır; hassas bilgileri repoya pushlamayın.
//
//   cp lib/config/api_config.example.dart lib/config/api_config.dart
// ---------------------------------------------------------------------------

class ApiConfig {
  final String baseUrl;
  const ApiConfig({this.baseUrl = 'https://api.example.com/v1/api'});

  /// Backend tenant / kuruluş tanımlayıcısı.
  static const String tenant = "your-tenant";

  static const String loginUrl = 'https://api.example.com/v1/auth/signin';
  static const String stationsUrl =
      'https://api.example.com/v1/api/charging-stations';
  static const String activeTransactionsUrl =
      'https://api.example.com/v1/api/transactions/status/active';
  static const String historyUrl =
      'https://api.example.com/v1/api/transactions/status/completed';
}
