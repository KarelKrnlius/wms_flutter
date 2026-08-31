import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService().getKartuStok();
      setState(() { _items = (res['data'] as List?) ?? []; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _items;
    final s = _search.toLowerCase();
    return _items.where((i) =>
      (i['nama'] ?? '').toLowerCase().contains(s) ||
      (i['sku']  ?? '').toLowerCase().contains(s)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    final items = _filtered;
    return Column(children: [
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(12),
        child: TextField(
          onChanged: (v) => setState(() => _search = v),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Cari barang...',
            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textHint),
            filled: true, fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
      ),
      const Divider(height: 1),
      Expanded(child: items.isEmpty
        ? const EmptyView(message: 'Tidak ada data kartu stok', icon: Icons.inventory_outlined)
        : RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i] as Map<String, dynamic>;
                final status = item['status_stok'] ?? 'Aman';
                final badgeType = status == 'Habis' ? BadgeType.danger : (status == 'Reorder' ? BadgeType.warning : BadgeType.success);
                final stokColor = status == 'Habis' ? AppColors.danger : (status == 'Reorder' ? AppColors.warning : AppColors.success);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: WmsCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item['nama'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(item['sku'] ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontFamily: 'monospace')),
                        const SizedBox(height: 4),
                        Row(children: [
                          StatusBadge(label: item['rack'] ?? '-', type: BadgeType.neutral),
                          const SizedBox(width: 6),
                          StatusBadge(label: status, type: badgeType),
                        ]),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${item['stok'] ?? 0}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: stokColor)),
                        Text('/ ${item['min_stok'] ?? 0} min', style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                      ]),
                    ]),
                  ),
                );
              },
            ),
          )),
    ]);
  }
}
