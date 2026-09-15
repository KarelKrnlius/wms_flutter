import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_theme.dart';
import 'core/constants.dart';
import 'screens/auth/login_screen.dart';
import 'main_scaffold.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

/// main.dart - Entry point aplikasi Flutter WMS
///
/// Alur:
/// 1. Cek apakah ada token tersimpan (user sudah login sebelumnya?)
/// 2. Jika ada → langsung ke MainScaffold (halaman utama)
/// 3. Jika tidak → tampilkan LoginScreen

void main() async {
  // Pastikan Flutter siap sebelum memanggil SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  ErrorWidget.builder = (details) => Material(
    color: AppColors.background,
    child: Builder(
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.danger,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Halaman tidak dapat ditampilkan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kembali ke menu sebelumnya, lalu coba lagi. Jika masalah berulang, catat menu dan aktivitas terakhir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

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
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: true,
        overscroll: false,
      ),
      home: isLoggedIn ? const _SessionBootstrap() : const LoginScreen(),
    );
  }
}

class _SessionBootstrap extends StatefulWidget {
  const _SessionBootstrap();

  @override
  State<_SessionBootstrap> createState() => _SessionBootstrapState();
}

class _SessionBootstrapState extends State<_SessionBootstrap> {
  bool? _valid;

  @override
  void initState() {
    super.initState();
    _validate();
  }

  Future<void> _validate() async {
    try {
      final response = await ApiService().getSession();
      if (mounted) setState(() => _valid = response['success'] == true);
    } catch (_) {
      await AuthService().clearSession();
      if (mounted) setState(() => _valid = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_valid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _valid! ? const MainScaffold() : const LoginScreen();
  }
}
