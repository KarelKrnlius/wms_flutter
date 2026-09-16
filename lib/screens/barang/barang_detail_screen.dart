import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/external_file_service.dart';
import '../../widgets/common_widgets.dart';

/// BarangDetailScreen - Detail lengkap satu barang + histori transaksi

class BarangDetailScreen extends StatefulWidget {
  final String sku;
  const BarangDetailScreen({super.key, required this.sku});

  @override
  State<BarangDetailScreen> createState() => _BarangDetailScreenState();
}

class _BarangDetailScreenState extends State<BarangDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        ApiService().getBarangDetail(widget.sku),
        AuthService().isAdmin(),
      ]);
      final res = results[0] as Map<String, dynamic>;
      setState(() {
        _data = res['data'];
        _isAdmin = results[1] as bool;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openLabel() async {
    try {
      final response = await ApiService().getItemLabelLink(widget.sku);
      final url = response['data']['url']?.toString() ?? '';
      await openExternalDocument(url, 'Label QR PDF');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.sku,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
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
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final stokStatus = d['status_stok'] ?? 'Aman';
    final badgeType = stokStatus == 'Habis'
        ? BadgeType.danger
        : (stokStatus == 'Reorder' ? BadgeType.warning : BadgeType.success);

    final inboundH = (d['inbound_history'] as List?) ?? [];
    final outboundH = (d['outbound_history'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- MAIN INFO CARD ----
          WmsCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['nama'] ?? '-',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d['sku'] ?? '-',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${d['stok'] ?? 0}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: stokStatus == 'Habis'
                                ? AppColors.danger
                                : (stokStatus == 'Reorder'
                                      ? AppColors.warning
                                      : AppColors.success),
                          ),
                        ),
                        Text(
                          d['satuan'] ?? 'PCS',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StatusBadge(
                      label: d['kategori'] ?? '-',
                      type: BadgeType.neutral,
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(label: stokStatus, type: badgeType),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),
                _infoRow('Satuan', d['satuan'] ?? 'PCS'),
                _infoRow('Harga Dasar', _fmtRupiah(d['harga_dasar'])),
                _infoRow(
                  'Min. Stok',
                  '${d['min_stok'] ?? 0} ${d['satuan'] ?? 'PCS'}',
                ),
                _infoRow('Lokasi Rak', d['kode_rak'] ?? d['rack'] ?? '-'),
                _infoRow('Nilai Barang', _fmtRupiah(d['nilai_barang'])),
                const SizedBox(height: 10),
                if (_isAdmin)
                  OutlinedButton.icon(
                    onPressed: _openLabel,
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Buka Label QR PDF'),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'QR Barcode hanya tersedia untuk akun Guru / Admin.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ---- HISTORI INBOUND ----
          if (inboundH.isNotEmpty) ...[
            const Text(
              'Histori Inbound (10 Terakhir)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            WmsCard(
              child: Column(
                children: inboundH.asMap().entries.map((e) {
                  final h = e.value as Map<String, dynamic>;
                  return _HistoryRow(
                    noRef: h['no_receiving'] ?? '-',
                    tanggal: h['tanggal'] ?? '-',
                    keterangan: h['supplier'] ?? '-',
                    qty: '+${h['qty']}',
                    qtyColor: AppColors.success,
                    isLast: e.key == inboundH.length - 1,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ---- HISTORI OUTBOUND ----
          if (outboundH.isNotEmpty) ...[
            const Text(
              'Histori Outbound (10 Terakhir)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            WmsCard(
              child: Column(
                children: outboundH.asMap().entries.map((e) {
                  final h = e.value as Map<String, dynamic>;
                  return _HistoryRow(
                    noRef: h['no_shipping'] ?? '-',
                    tanggal: h['tanggal'] ?? '-',
                    keterangan: h['customer'] ?? '-',
                    qty: '-${h['qty']}',
                    qtyColor: AppColors.danger,
                    isLast: e.key == outboundH.length - 1,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(': ', style: const TextStyle(color: AppColors.textHint)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtRupiah(dynamic v) {
    if (v == null) return 'Rp 0';
    final n = v is num ? v : num.tryParse(v.toString()) ?? 0;
    if (n >= 1000000) return 'Rp ${(n / 1000000).toStringAsFixed(1)}Jt';
    if (n >= 1000) return 'Rp ${(n / 1000).toStringAsFixed(0)}rb';
    return 'Rp $n';
  }
}

class _HistoryRow extends StatelessWidget {
  final String noRef;
  final String tanggal;
  final String keterangan;
  final String qty;
  final Color qtyColor;
  final bool isLast;

  const _HistoryRow({
    required this.noRef,
    required this.tanggal,
    required this.keterangan,
    required this.qty,
    required this.qtyColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      noRef,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      keterangan,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      tanggal,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                qty,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: qtyColor,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
