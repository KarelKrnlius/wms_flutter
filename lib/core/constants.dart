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
  static const String baseUrl = 'https://alkalize-unbend-muscular.ngrok-free.dev';
  // static const String baseUrl = 'http://localhost:8000';   // Windows/Chrome lokal
  // static const String baseUrl = 'http://10.0.2.2:8000';   // Android Emulator

  static const String apiUrl   = '$baseUrl/api';
  static const String tokenKey = 'wms_token';
  static const String userKey  = 'wms_user';
}
