// constants.dart
// Semua nilai tetap (URL, warna, dsb.) dipusatkan di sini.
// Kalau mau ganti URL server, cukup ubah satu baris di sini.

class AppConstants {
  // ============================================================
  // BASE URL API — pilih sesuai perangkat yang dipakai
  // ============================================================
  //
  // 1. Emulator Android (AVD bawaan Android Studio):
  //    'http://10.0.2.2:8000'
  //
  // 2. HP Fisik via WiFi (cek IP laptop: ipconfig di CMD):
  //    'http://192.168.X.X:8000'
  //
  // 3. Genymotion:
  //    'http://10.0.3.2:8000'
  //
  static const String baseUrl = 'http://10.0.2.2:8000';

  static const String apiUrl   = '$baseUrl/api';
  static const String tokenKey = 'wms_token';
  static const String userKey  = 'wms_user';
}
