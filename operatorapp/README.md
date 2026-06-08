<p align="center">
  <img src="assets/icons/app_icon.png" alt="Uygulama Logosu" width="120" />
</p>

<h1 align="center">⚡ EV Şarj İzleme — Operatör Uygulaması</h1>

<p align="center">
  Flutter ile geliştirilmiş, elektrikli araç (EV) şarj istasyonlarını gerçek
  zamanlı olarak izlemek ve yönetmek için tasarlanmış mobil operatör uygulaması.
</p>

> **Not:** Bu repo bir portföy/örnek projedir. Uygulamanın bağlandığı backend, sunucu adresleri ve kimlik bilgileri repoya dahil edilmemiştir; çalıştırmak için kendi API yapılandırmanızı sağlamanız gerekir (bkz. [Yapılandırma](#-yapılandırma)).

---

## 📱 Ekran Görüntüleri

Uygulama; giriş ekranı, canlı izleme, aktif işlemler ve geçmiş sekmelerinden oluşur.

| Giriş | Canlı İzleme | Aktif İşlemler | Geçmiş |
|:---:|:---:|:---:|:---:|
| <img src="screenshots/login.png" width="180" /> | <img src="screenshots/live.png" width="180" /> | <img src="screenshots/active.png" width="180" /> | <img src="screenshots/history.png" width="180" /> |

> 📷 Ekran görüntülerinizi `screenshots/` klasörüne `login.png`, `live.png`,
> `active.png` ve `history.png` adlarıyla ekleyin; görseller otomatik olarak burada
> gösterilecektir.

---

## 🚀 Özellikler

- **Güvenli Kimlik Doğrulama** — JWT tabanlı oturum yönetimi ve otomatik yeniden giriş (auto-relogin)
- **Canlı İzleme (Live Tab)** — Şarj istasyonlarını ve bağlayıcı durumlarını gerçek zamanlı görüntüleme
- **Aktif İşlemler (Active Tab)** — Anlık devam eden şarj oturumlarını listeleme
- **Geçmiş (History Tab)** — Tamamlanmış şarj işlemlerini filtreleme (AC/DC, tarih aralığı vb.)
- **Karanlık / Aydınlık Tema** — Sistem temasını otomatik takip eder
- **Animasyonlu UI** — Shimmer yükleme efektleri ve staggered animasyonlar

---

## 🏗️ Proje Yapısı

```
lib/
├── main.dart                  # Uygulama giriş noktası & AuthWrapper
├── config/
│   ├── api_config.example.dart # API yapılandırma şablonu (bu dosyayı kopyalayın)
│   └── app_theme.dart         # Tema tanımları (light/dark)
├── models/
│   ├── charging_station.dart  # İstasyon modeli
│   ├── connector.dart         # Bağlayıcı modeli
│   ├── charging_history.dart  # Geçmiş işlem modeli
│   ├── charging_data.dart     # Şarj verisi
│   └── history_stats.dart     # Geçmiş istatistik modeli
├── services/
│   └── auth_service.dart      # JWT yönetimi, giriş/çıkış, token doğrulama
├── repositories/
│   └── data_repository.dart   # API çağrıları ve veri yönetimi
├── screens/
│   ├── login_screen.dart      # Giriş ekranı
│   ├── home_screen.dart       # Ana ekran (tab navigasyonu)
│   └── tabs/
│       ├── live_tab.dart      # Canlı izleme sekmesi
│       ├── active_tab.dart    # Aktif işlemler sekmesi
│       └── history_tab.dart   # Geçmiş sekmesi
├── widgets/                   # Yeniden kullanılabilir bileşenler
├── data/                      # Yerel veri / sabitler
└── utils/                     # Yardımcı fonksiyonlar
```

---

## 🛠️ Kullanılan Teknolojiler

| Paket | Sürüm | Amaç |
|---|---|---|
| `flutter` | SDK | Temel framework |
| `flutter_riverpod` | ^2.5.1 | State management |
| `http` | ^1.2.2 | REST API istekleri |
| `flutter_secure_storage` | ^9.2.2 | Token güvenli depolama |
| `shared_preferences` | ^2.2.2 | Yerel tercihler |
| `google_fonts` | ^6.2.1 | Typography |
| `google_nav_bar` | ^5.0.6 | Alt navigasyon çubuğu |
| `flutter_staggered_animations` | ^1.1.1 | Liste animasyonları |
| `shimmer` | ^3.0.0 | Yükleme efekti |
| `intl` | ^0.19.0 | Tarih/saat biçimlendirme |

---

## ⚙️ Kurulum ve Çalıştırma

### Gereksinimler

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.8.1
- Dart SDK ≥ 3.8.1
- Android Studio veya VS Code
- Android Emulator / Fiziksel Cihaz (Android API 21+)

### Adımlar

```bash
# 1. Repoyu klonlayın
git clone https://github.com/YlmTalha/charge-station-operator-panel.git
cd charge-station-operator-panel/operatorapp

# 2. API yapılandırmasını oluşturun (aşağıdaki "Yapılandırma" bölümüne bakın)
cp lib/config/api_config.example.dart lib/config/api_config.dart
# ardından lib/config/api_config.dart içindeki değerleri kendi backend'inizle güncelleyin

# 3. Bağımlılıkları yükleyin
flutter pub get

# 4. Uygulamayı çalıştırın
flutter run
```

---

## 🔑 Yapılandırma

API ayarları `lib/config/api_config.dart` dosyasında tanımlanır. Bu dosya hassas
bilgiler (sunucu adresleri, tenant) içerebileceği için **repoya dahil edilmez** ve
`.gitignore` ile takip dışı bırakılmıştır.

Başlamak için şablon dosyayı kopyalayın:

```bash
cp lib/config/api_config.example.dart lib/config/api_config.dart
```

Ardından kendi backend bilgilerinizi girin:

```dart
class ApiConfig {
  static const String tenant        = 'your-tenant';
  static const String loginUrl      = 'https://api.example.com/v1/auth/signin';
  static const String stationsUrl   = 'https://api.example.com/v1/api/charging-stations';
  static const String historyUrl    = 'https://api.example.com/v1/api/transactions/status/completed';
  // ...
}
```

> ⚠️ **Not:** Geliştirme ortamında SSL sertifika doğrulaması devre dışı bırakılabilir
> (`MyHttpOverrides`). **Production ortamında bu davranış kaldırılmalı** veya geçerli,
> güvenilir bir sertifika kullanılmalıdır.

---

## 📦 Desteklenen Platformlar

| Platform | Durum |
|---|---|
| Android | ✅ Destekleniyor (API 21+) |
| iOS | ✅ Destekleniyor |
| Web | ⚠️ Kısmi destek |
| Windows | ⚠️ Kısmi destek |
| macOS / Linux | ⚠️ Kısmi destek |

---

## 🔒 Kimlik Doğrulama Akışı

```
Uygulama Başlangıcı
       │
       ▼
  Token Kontrolü
  /           \
Geçerli    Geçersiz
  │              │
  │         Auto-Relogin
  │         /          \
  │      Başarılı    Başarısız
  │          │             │
  ▼          ▼             ▼
HomeScreen            LoginScreen
```

Kimlik bilgileri ve token'lar `flutter_secure_storage` ile cihazda şifreli olarak
saklanır; kaynak kodda herhangi bir sabit (hardcoded) kimlik bilgisi bulunmaz.

---

## 📄 Lisans

Bu proje özel (private) amaçla geliştirilmiştir. Aksi belirtilmedikçe tüm hakları saklıdır.
