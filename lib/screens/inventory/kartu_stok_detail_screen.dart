import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

/// KartuStokDetailScreen - Timeline mutasi stok per barang
/// Meniru tampilan web: tabel tanggal, jenis, no_ref, qty_in, qty_out, saldo

class KartuStokDetailScreen extends StatefulWidget {
  final String sku;
  final String? namaBarang;

  const KartuStokDetailScreen({super.key, required this.sku, this.namaBarang});

  @override
  State<KartuStokDetailScreen> createState() => _KartuStokDetailScreenState();
}

class _KartuStokDetailScreenState extends State<KartuStokDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService().getKartuStokDetail(widget.sku);
      setState(() { _data = res['data']; _loading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.namaBarang ?? widget.sku,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
            Text('Kartu Stok — ${widget.sku}',
                style: const TextStyle(fontSize: 10, color: AppColors.textHint, fontFamily: 'monospace')),
          ],
        ),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final barang = _data!['barang'] as Map<String, dynamic>;
    final mutations = (_data!['mutations'] as List?) ?? [];
    final stok = barang['stok'] ?? 0;
    final minStok = barang['min_stok'] ?? 0;
    // Cocok dengan web: hijau jika stok > Min_Stok, merah jika tidak
    final stokColor = stok > minStok ? AppColors.success : AppColors.danger;
    final isReorder = stok <= minStok;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- INFO CARD (meniru web: nama, grid 4 kolom, stok kanan, reorder badge) ----
          WmsCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kiri: nama + grid info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(barang['nama'] ?? '-',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          const SizedBox(height: 10),
                          // Grid 4 kolom: SKU | Kategori | Lokasi Rak | Min. Stok
                          Row(
                            children: [
                              _infoCell('SKU', barang['sku'] ?? '-', mono: true, color: AppColors.primary),
                              _infoCell('Kategori', barang['kategori'] ?? '-'),
                              _infoCell('Lokasi Rak', barang['rack'] ?? '-', mono: true),
                              _infoCell('Min. Stok', '$minStok unit', mono: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Kanan: Stok Saat Ini + reorder badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Stok Saat Ini',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                letterSpacing: 1, color: AppColors.textHint)),
                        Text('$stok',
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900,
                                fontFamily: 'monospace', color: stokColor)),
                        const Text('unit', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                        if (isReorder) ...[
                          const SizedBox(height: 4),
                          StatusBadge(label: '⚠ Reorder Point', type: BadgeType.warning),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                // Summary row
                Row(
                  children: [
                    _statMini('Total Mutasi', '${mutations.length}', AppColors.primary),
                    _divMini(),
                    _statMini('Inbound', '${mutations.where((m) => m['jenis'] == 'Inbound').length}', AppColors.success),
                    _divMini(),
                    _statMini('Outbound', '${mutations.where((m) => m['jenis'] == 'Outbound').length}', AppColors.danger),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ---- TIMELINE HEADER ----
          Row(
            children: [
              const Icon(Icons.timeline, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Timeline Mutasi Stok',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              StatusBadge(label: '${mutations.length} mutasi', type: BadgeType.neutral),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Terbaru di atas. Saldo dihitung kumulatif.',
              style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          const SizedBox(height: 10),

          // ---- TIMELINE LIST ----
          if (mutations.isEmpty)
            const EmptyView(message: 'Belum ada mutasi stok', icon: Icons.timeline)
          else
            WmsCard(
              child: Column(
                children: mutations.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final m   = entry.value as Map<String, dynamic>;
                  final isInbound  = m['jenis'] == 'Inbound';
                  final qtyIn  = m['qty_in']  ?? 0;
                  final qtyOut = m['qty_out'] ?? 0;
                  final saldo  = m['saldo']   ?? 0;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Jenis badge + tanggal (kolom kiri)
                            SizedBox(
                              width: 80,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isInbound ? AppColors.successBg : AppColors.dangerBg,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isInbound ? Icons.arrow_downward : Icons.arrow_upward,
                                          size: 10,
                                          color: isInbound ? AppColors.success : AppColors.danger,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          isInbound ? 'IN' : 'OUT',
                                          style: TextStyle(
                                            fontSize: 9, fontWeight: FontWeight.w800,
                                            color: isInbound ? AppColors.success : AppColors.danger,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(m['tanggal'] ?? '-',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textHint, fontFamily: 'monospace')),
                                ],
                              ),
                            ),
                            // No referensi + operator
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m['no_ref'] ?? '-',
                                      style: const TextStyle(
                                          fontSize: 11, fontFamily: 'monospace',
                                          fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  if ((m['operator'] ?? '-') != '-')
                                    Text(m['operator'],
                                        style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                                ],
                              ),
                            ),
                            // Qty in/out
                            SizedBox(
                              width: 50,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (qtyIn > 0)
                                    Text('+$qtyIn',
                                        style: const TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w800,
                                            color: AppColors.success, fontFamily: 'monospace')),
                                  if (qtyOut > 0)
                                    Text('-$qtyOut',
                                        style: const TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w800,
                                            color: AppColors.danger, fontFamily: 'monospace')),
                                ],
                              ),
                            ),
                            // Saldo
                            SizedBox(
                              width: 55,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Saldo', style: TextStyle(fontSize: 9, color: AppColors.textHint)),
                                  Text('$saldo',
                                      style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w900,
                                          fontFamily: 'monospace',
                                          color: saldo > 0 ? AppColors.textPrimary : AppColors.danger)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (idx < mutations.length - 1)
                        const Divider(height: 1, indent: 14, endIndent: 14),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // Grid cell untuk info barang (meniru web 4-kolom)
  Widget _infoCell(String label, String value, {bool mono = false, Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color ?? AppColors.textPrimary,
                fontFamily: mono ? 'monospace' : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _statMini(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _divMini() => Container(
    width: 1, height: 32, color: AppColors.border,
  );
}

