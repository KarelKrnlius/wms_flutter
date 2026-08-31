import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});
  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService().getSuppliers(search: _search.isEmpty ? null : _search);
      setState(() { _items = (res['data'] as List?) ?? []; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    return Column(children: [
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(12),
        child: TextField(
          onChanged: (v) { _search = v; _load(); },
          decoration: InputDecoration(
            hintText: 'Cari supplier...',
            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textHint),
            filled: true, fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
      ),
      const Divider(height: 1),
      Expanded(child: _items.isEmpty
        ? const EmptyView(message: 'Belum ada data supplier', icon: Icons.business_outlined)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            itemBuilder: (ctx, i) {
              final s = _items[i] as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: WmsCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.business, size: 20, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['nama'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      if ((s['no_kontak'] ?? '').toString().isNotEmpty)
                        Text(s['no_kontak'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      StatusBadge(label: '${s['total_transaksi'] ?? 0} transaksi', type: BadgeType.primary),
                    ])),
                  ]),
                ),
              );
            },
          )),
    ]);
  }
}
