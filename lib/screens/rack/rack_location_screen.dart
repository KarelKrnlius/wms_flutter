import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import 'rack_detail_screen.dart';

/// RackLocationScreen - Daftar Lokasi Rak
class RackLocationScreen extends StatefulWidget {
  const RackLocationScreen({super.key});
  @override
  State<RackLocationScreen> createState() => _RackLocationScreenState();
}

class _RackLocationScreenState extends State<RackLocationScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  bool _isAdmin = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    AuthService().isAdmin().then((value) {
      if (mounted) setState(() => _isAdmin = value);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService().getRackLocations(
        search: _search.isEmpty ? null : _search,
      );
      setState(() {
        _items = (res['data'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Penuh':
        return AppColors.danger;
      case 'Hampir Penuh':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  BadgeType _statusBadge(String status) {
    switch (status) {
      case 'Penuh':
        return BadgeType.danger;
      case 'Hampir Penuh':
        return BadgeType.warning;
      default:
        return BadgeType.success;
    }
  }

  Future<void> _rackForm([Map<String, dynamic>? rack]) async {
    final formKey = GlobalKey<FormState>();
    final code = TextEditingController(text: rack?['kode_rak']?.toString());
    final aisle = TextEditingController(text: rack?['aisle']?.toString());
    final level = TextEditingController(text: rack?['level']?.toString());
    final capacity = TextEditingController(
      text: rack?['kapasitas']?.toString(),
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(rack == null ? 'Tambah Lokasi Rak' : 'Edit Lokasi Rak'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: code,
                    decoration: const InputDecoration(labelText: 'Kode rak'),
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: aisle,
                    decoration: const InputDecoration(
                      labelText: 'Lorong / aisle',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: level,
                    decoration: const InputDecoration(labelText: 'Level'),
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: capacity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Kapasitas'),
                    validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                        ? 'Kapasitas minimal 1'
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved == true) {
      try {
        final payload = {
          'Kode_Rak': code.text.trim(),
          'Aisle': aisle.text.trim(),
          'Level': level.text.trim(),
          'Kapasitas': int.parse(capacity.text),
        };
        final response = rack == null
            ? await ApiService().createRack(payload)
            : await ApiService().updateRack(
                rack['rack_id'].toString(),
                payload,
              );
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response['message'])));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
            ),
          );
        }
      }
    }
    code.dispose();
    aisle.dispose();
    level.dispose();
    capacity.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

  Future<void> _deleteRack(Map<String, dynamic> rack) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus lokasi rak?'),
        content: Text(
          'Rak ${rack['kode_rak']} hanya dapat dihapus jika belum memiliki histori transaksi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final response = await ApiService().deleteRack(
        rack['rack_id'].toString(),
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message'])));
      }
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
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    _search = v;
                    _load();
                  },
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cari kode rak / lorong...',
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              _search = '';
                              _load();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              if (_isAdmin) ...[
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _rackForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Rak'),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
              ? const EmptyView(
                  message: 'Belum ada data lokasi rak',
                  icon: Icons.storage_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final r = _items[i] as Map<String, dynamic>;
                      final status = r['status_kapasitas'] ?? 'Tersedia';
                      final terpakai = r['kapasitas_terpakai'] ?? 0;
                      final kapasitas = r['kapasitas'] ?? 1;
                      final pct = kapasitas > 0
                          ? (terpakai / kapasitas).clamp(0.0, 1.0)
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RackDetailScreen(id: r['rack_id'].toString()),
                            ),
                          ).then((_) => _load()),
                          child: WmsCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLow,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.storage_outlined,
                                        size: 20,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r['kode_rak'] ?? '-',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'monospace',
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Lorong ${r['aisle'] ?? '-'} — Level ${r['level'] ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(
                                      label: status,
                                      type: _statusBadge(status),
                                    ),
                                    if (_isAdmin)
                                      IconButton(
                                        onPressed: () => _rackForm(r),
                                        tooltip: 'Edit rak',
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                      ),
                                    if (_isAdmin)
                                      IconButton(
                                        onPressed: () => _deleteRack(r),
                                        tooltip: 'Hapus rak',
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Progress bar kapasitas
                                Row(
                                  children: [
                                    const Text(
                                      'Kapasitas: ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '$terpakai / $kapasitas unit',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _statusColor(status),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 6,
                                    backgroundColor: AppColors.surfaceLow,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _statusColor(status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
