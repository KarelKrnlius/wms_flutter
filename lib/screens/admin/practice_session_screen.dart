import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({super.key});
  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiService().getPracticeSessions();
      if (mounted) {
        setState(() {
          _items = r['data'] ?? [];
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _create() async {
    final name = TextEditingController(),
        studentClass = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Buka Sesi Praktikum'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama sesi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: studentClass,
                decoration: const InputDecoration(
                  labelText: 'Kelas (opsional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Buka sesi'),
          ),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      try {
        await ApiService().createPracticeSession({
          'name': name.text.trim(),
          'class': studentClass.text.trim(),
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
    name.dispose();
    studentClass.dispose();
  }

  Future<void> _close(String id) async {
    try {
      await ApiService().closePracticeSession(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    final hasActive = _items.any((row) => row['status'] == 'active');
    return ListView(
      padding: context.pagePadding,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: hasActive ? null : _create,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Buka Sesi'),
          ),
        ),
        const SizedBox(height: 14),
        ..._items.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: WmsCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    row['status'] == 'active'
                        ? Icons.play_circle_fill
                        : Icons.check_circle,
                    color: row['status'] == 'active'
                        ? AppColors.success
                        : AppColors.textHint,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row['name'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${row['class'] ?? 'Tanpa kelas'} • ${row['date']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: row['status'] == 'active' ? 'Aktif' : 'Selesai',
                    type: row['status'] == 'active'
                        ? BadgeType.success
                        : BadgeType.neutral,
                  ),
                  if (row['status'] == 'active')
                    TextButton(
                      onPressed: () => _close(row['id'].toString()),
                      child: const Text('Tutup'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
