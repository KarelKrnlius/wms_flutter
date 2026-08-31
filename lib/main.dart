import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_theme.dart';
import 'core/constants.dart';
import 'screens/auth/login_screen.dart';
import 'main_scaffold.dart';

/// main.dart - Entry point aplikasi Flutter WMS
///
/// Alur:
/// 1. Cek apakah ada token tersimpan (user sudah login sebelumnya?)
/// 2. Jika ada → langsung ke MainScaffold (halaman utama)
/// 3. Jika tidak → tampilkan LoginScreen

void main() async {
  // Pastikan Flutter siap sebelum memanggil SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  // Cek status login
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.containsKey(AppConstants.tokenKey);

  runApp(WmsApp(isLoggedIn: isLoggedIn));
}

class WmsApp extends StatelessWidget {
  final bool isLoggedIn;
  const WmsApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WMS Prototipe 2',
      debugShowCheckedModeBanner: false,
      // Terapkan tema global yang meniru tampilan web WMS
      theme: AppTheme.theme,
      home: isLoggedIn ? const MainScaffold() : const LoginScreen(),
    );
  }
}
