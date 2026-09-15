// constants.dart
//
// ╔══════════════════════════════════════════════════════════════╗
// ║  CARA GANTI URL SESUAI ENVIRONMENT                          ║
// ╠══════════════════════════════════════════════════════════════╣
// ║  NGROK (HP Fisik / Emulator / Chrome — direkomendasikan)    ║
// ║    baseUrl = 'https://xxxx-xxxx.ngrok-free.app'             ║
// ║                                                              ║
// ║  Windows/Chrome lokal tanpa Ngrok                           ║
// ║    baseUrl = 'http://localhost:8000'                         ║
// ║                                                              ║
// ║  Android Emulator (AVD) tanpa Ngrok                         ║
// ║    baseUrl = 'http://10.0.2.2:8000'                         ║
// ║                                                              ║
// ║  HP Fisik via WiFi tanpa Ngrok                              ║
// ║    baseUrl = 'http://<IP-LAPTOP>:8000'  (cek: ipconfig)     ║
// ╚══════════════════════════════════════════════════════════════╝

class AppConstants {
  /// Set saat build/run, contoh:
  /// flutter run --dart-define=WMS_API_BASE_URL=http://10.0.2.2:8000
  /// flutter run -d windows --dart-define=WMS_API_BASE_URL=http://localhost:8000
  static const String baseUrl = String.fromEnvironment(
    'WMS_API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String apiUrl = '$baseUrl/api/v1';
  static const String tokenKey = 'wms_token';
  static const String userKey = 'wms_user';
}
