import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';

class InboundDetailScreen extends StatefulWidget {
  final String id;
  const InboundDetailScreen({super.key, required this.id});
  @override
  State<InboundDetailScreen> createState() => _InboundDetailScreenState();
}

class _InboundDetailScreenState extends State<InboundDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    AuthService().isAdmin().then((value) {
      if (mounted) setState(() => _isAdmin = value);
    });
  }

  Future<void> _cancel() async {
    final reason = TextEditingController();
    String? validationError;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Batalkan Inbound'),
          content: TextField(
            controller: reason,
            maxLines: 3,
            maxLength: 500,
            autofocus: true,
            onChanged: (value) => setDialogState(() {
              validationError = value.trim().length < 10
                  ? 'Alasan masih ${value.trim().length} karakter. Minimal 10 karakter.'
                  : null;
            }),
            decoration: InputDecoration(
              labelText: 'Alasan pembatalan',
              helperText: 'Jelaskan alasan secara singkat dan jelas.',
              errorText: validationError,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Kembali'),
            ),
            FilledButton.tonal(
              onPressed: reason.text.trim().length >= 10
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Batalkan inbound'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      try {
        final response = await ApiService().cancelInbound(
          widget.id,
          reason.text.trim(),
        );
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Inbound dibatalkan.'),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
    reason.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService().getInboundDetail(widget.id);
      setState(() {
        _data = res['data'];
        _loading = false;
      });
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
        title: Text(
          _data?['no_receiving'] ?? 'Detail Inbound',
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
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _data!;
    final isCancelled = d['transaction_status'] == 'cancelled';
    final details = (d['details'] as List?) ?? [];
    final supplier = d['supplier'] as Map<String, dynamic>?;
    String rupiah(dynamic value) {
      final amount = value is num
          ? value
          : num.tryParse(value?.toString() ?? '') ?? 0;
      return 'Rp ${NumberFormat('#,###', 'id_ID').format(amount)}';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCancelled) ...[
            _CancelledBanner(
              message:
                  'Transaksi inbound ini telah dibatalkan dan tidak lagi menambah stok.',
            ),
            const SizedBox(height: 12),
          ],
          WmsCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? AppColors.dangerBg
                            : AppColors.successBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCancelled
                            ? Icons.cancel_outlined
                            : Icons.arrow_downward_rounded,
                        size: 18,
                        color: isCancelled
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['no_receiving'] ?? '-',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          d['tanggal'] ?? '-',
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
                const Divider(),
                const SizedBox(height: 8),
                if (supplier != null) ...[
                  _row('Supplier', supplier['nama'] ?? '-'),
                  _row('Kontak', supplier['no_kontak'] ?? '-'),
                ],
                _row('Operator', d['operator'] ?? '-'),
                _row('Status', isCancelled ? 'Dibatalkan' : 'Berhasil'),
                if ((d['catatan'] ?? '').toString().isNotEmpty)
                  _row('Catatan', d['catatan'].toString()),
                if (_isAdmin && d['transaction_status'] != 'cancelled') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _cancel,
                    icon: const Icon(Icons.block),
                    label: const Text('Batalkan Inbound'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Detail Barang (${details.length} item)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          WmsCard(
            child: Column(
              children: details.asMap().entries.map((e) {
                final det = e.value as Map<String, dynamic>;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  det['nama_barang'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  det['sku'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                StatusBadge(
                                  label: 'Rak: ${det['rack'] ?? '-'}',
                                  type: BadgeType.neutral,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${rupiah(det['harga_satuan'])} × ${det['qty']} = ${rupiah(det['subtotal'])}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+${det['qty']} ${det['satuan'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (e.key < details.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          WmsCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Nilai Inbound',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Akumulasi subtotal seluruh barang',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  rupiah(d['total_nilai']),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(color: AppColors.textHint)),
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

class _CancelledBanner extends StatelessWidget {
  const _CancelledBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.dangerBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.danger.withValues(alpha: .35)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cancel_outlined, color: AppColors.danger),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
