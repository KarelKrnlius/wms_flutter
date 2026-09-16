import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../main_scaffold.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/wms_logo.dart';
import 'student_identity_dialog.dart';

/// LoginScreen - Halaman login WMS Flutter

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formGlobal = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePwd = true;
  String? _errorMsg;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (!_formGlobal.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final result = await ApiService().login(
        _loginCtrl.text.trim(),
        _passCtrl.text,
      );

      if (result['success'] == true) {
        await AuthService().saveSession(
          result['token'] as String,
          result['user'] as Map<String, dynamic>,
        );

        if (!mounted) return;
        if (result['requires_student_identity'] == true) {
          final completed = await showStudentIdentityDialog(context);
          if (!completed || !mounted) return;
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScaffold()),
          (route) => false,
        );
      } else {
        setState(() => _errorMsg = result['message'] ?? 'Login gagal.');
      }
    } catch (e) {
      setState(() => _errorMsg = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 1000) return _loginPanel();
    return Scaffold(
      body: Row(
        children: [
          const Expanded(flex: 6, child: _DesktopLoginHero()),
          Expanded(flex: 5, child: _loginPanel()),
        ],
      ),
    );
  }

  Widget _loginPanel() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width <= 360 ? 16 : 24,
          ),
          child: Form(
            key: _formGlobal,
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ---- LOGO ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const WmsLogo(size: 48),
                    const SizedBox(width: 12),
                    const Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WMS Prototipe 2',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Warehouse Management System',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ---- CARD FORM ----
                WmsCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Masuk ke Sistem',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Gunakan kredensial yang diberikan oleh instruktur.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Error message
                      if (_errorMsg != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber,
                                size: 16,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMsg!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Field Username
                      WmsTextField(
                        label: 'Username atau Email',
                        hint: 'admin / siswa',
                        controller: _loginCtrl,
                        prefixIcon: Icons.person_outline,
                        validator: (v) => v == null || v.isEmpty
                            ? 'Username wajib diisi'
                            : null,
                      ),

                      const SizedBox(height: 16),

                      // Field Password
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePwd,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Password wajib diisi'
                                : null,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: AppColors.textHint,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePwd
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 16,
                                  color: AppColors.textHint,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePwd = !_obscurePwd),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      WmsButton(
                        label: 'Masuk',
                        icon: Icons.login,
                        onPressed: _doLogin,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ---- HINT KREDENSIAL ----
                WmsCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Kredensial Default',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _credRow('Guru (Admin)', 'admin', 'password'),
                      const SizedBox(height: 6),
                      _credRow('Siswa (User)', 'siswa', 'password'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'WMS Prototipe 2 • Versi 1.0.6 (Build 7) © 2026',
                  style: TextStyle(fontSize: 10, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _credRow(String role, String user, String pass) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final credentials = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _codeChip(user),
            const Text(
              ' / ',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            _codeChip(pass),
          ],
        );

        final roleLabel = Text(
          role,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        );

        if (constraints.maxWidth < 280) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [roleLabel, const SizedBox(height: 4), credentials],
          );
        }

        return Row(
          children: [
            SizedBox(width: 90, child: roleLabel),
            credentials,
          ],
        );
      },
    );
  }

  Widget _codeChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DesktopLoginHero extends StatelessWidget {
  const _DesktopLoginHero();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.dark,
      child: Stack(
        children: [
          Positioned(
            right: -120,
            top: -80,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: .22),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const WmsLogo(size: 84),
                const SizedBox(height: 32),
                const Text(
                  'Warehouse Management\nSystem',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kelola penerimaan, penyimpanan, picking, dan pengiriman dalam satu aplikasi desktop.',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 42),
                const Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _HeroChip(Icons.inventory_2_outlined, 'Stok real-time'),
                    _HeroChip(Icons.location_on_outlined, 'Lokasi rak'),
                    _HeroChip(Icons.fact_check_outlined, 'Jejak audit'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF93C5FD)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
