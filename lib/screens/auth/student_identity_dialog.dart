import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../services/api_service.dart';

Future<bool> showStudentIdentityDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _StudentIdentityDialog(),
  );
  return result == true;
}

class _StudentIdentityDialog extends StatefulWidget {
  const _StudentIdentityDialog();

  @override
  State<_StudentIdentityDialog> createState() => _StudentIdentityDialogState();
}

class _StudentIdentityDialogState extends State<_StudentIdentityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _studentClass = TextEditingController();
  final _nis = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _studentClass.dispose();
    _nis.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiService().saveStudentIdentity(
        name: _name.text.trim(),
        studentClass: _studentClass.text.trim(),
        nis: _nis.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.badge_outlined, color: AppColors.primary),
      title: const Text('Identitas Praktikum'),
      content: SizedBox(
        width: 430,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Isi identitas siswa sebelum menjalankan transaksi. Data ini dicatat pada activity log.',
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 3
                      ? 'Nama lengkap minimal 3 karakter'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _studentClass,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Kelas',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Kelas wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nis,
                  keyboardType: TextInputType.number,
                  maxLines: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'NIS',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (value) =>
                      RegExp(r'^\d+$').hasMatch(value?.trim() ?? '')
                      ? null
                      : 'NIS wajib diisi dengan angka saja',
                  onFieldSubmitted: (_) => _save(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(_saving ? 'Menyimpan…' : 'Mulai Praktikum'),
        ),
      ],
    );
  }
}
