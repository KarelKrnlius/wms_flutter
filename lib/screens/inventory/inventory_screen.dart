import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'kartu_stok_detail_screen.dart';

/// Kartu Stok Index - Daftar semua barang + stok real-time
/// Meniru tampilan web: tabel SKU, Nama, Kategori, Rack, Stok, Status + tombol Timeline

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

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _items;
    final s = _search.toLowerCase();
    return _items.where((item) =>
      (item['nama']     ?? '').toLowerCase().contains(s) ||
      (item['sku']      ?? '').toLowerCase().contains(s) ||
      (item['kategori'] ?? '').toLowerCase().contains(s)
    ).toList();
  }

  Color _stokColor(String status) {
    if (status == 'Habis') return AppColors.danger;
    if (status == 'Reorder') return const Color(0xFF93000A); // sesuai web: text-[#93000a]
    return AppColors.textPrimary; // Aman
  }

  BadgeType _badge(String status) => status == 'Habis'
      ? BadgeType.danger
      : (status == 'Reorder' ? BadgeType.warning : BadgeType.success);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final items = _filtered;

    return Column(
      children: [
        // ---- HEADER & SEARCH ----
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kartu Stok Seluruh Barang',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text('Klik item untuk melihat timeline mutasi',
                            style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cari SKU / nama / kategori...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ---- SUMMARY ROW ----
        Container(
          color: AppColors.surfaceLow,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('${items.length} barang', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              StatusBadge(label: '${items.where((i) => i['status_stok'] == 'Habis').length} Habis', type: BadgeType.danger),
              const SizedBox(width: 6),
              StatusBadge(label: '${items.where((i) => i['status_stok'] == 'Reorder').length} Reorder', type: BadgeType.warning),
              const SizedBox(width: 6),
              StatusBadge(label: '${items.where((i) => i['status_stok'] == 'Aman').length} Aman', type: BadgeType.success),
            ],
          ),
        ),

        // ---- LIST ----
        Expanded(
          child: items.isEmpty
              ? EmptyView(
                  message: _search.isNotEmpty ? 'Tidak ada hasil untuk "$_search"' : 'Belum ada data kartu stok',
                  icon: Icons.inventory_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i] as Map<String, dynamic>;
                      final status = item['status_stok'] ?? 'Aman';
                      return _KartuStokCard(
                        item: item,
                        status: status,
                        stokColor: _stokColor(status),
                        badgeType: _badge(status),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KartuStokDetailScreen(
                              sku: item['sku'],
                              namaBarang: item['nama'],
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

class _KartuStokCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String status;
  final Color stokColor;
  final BadgeType badgeType;
  final VoidCallback onTap;

  const _KartuStokCard({
    required this.item,
    required this.status,
    required this.stokColor,
    required this.badgeType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: WmsCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon status
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: status == 'Habis'
                      ? AppColors.dangerBg
                      : (status == 'Reorder' ? AppColors.warningBg : AppColors.successBg),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  status == 'Habis'
                      ? Icons.remove_circle_outline
                      : (status == 'Reorder' ? Icons.warning_amber_outlined : Icons.check_circle_outline),
                  size: 20,
                  color: status == 'Habis'
                      ? AppColors.danger
                      : (status == 'Reorder' ? AppColors.warning : AppColors.success),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['nama'] ?? '-',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(item['sku'] ?? '-',
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(children: [
                      StatusBadge(label: item['kategori'] ?? '-', type: BadgeType.neutral),
                      const SizedBox(width: 6),
                      StatusBadge(label: 'Rak: ${item['rack'] ?? '-'}', type: BadgeType.neutral),
                    ]),
                  ],
                ),
              ),
              // Stok + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${item['stok'] ?? 0}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: stokColor)),
                  if (status == 'Reorder' || status == 'Habis')
                    Text('min: ${item['min_stok'] ?? 0}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textHint))
                  else
                    const SizedBox(height: 14),
                  const SizedBox(height: 4),
                  StatusBadge(label: status, type: badgeType),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
