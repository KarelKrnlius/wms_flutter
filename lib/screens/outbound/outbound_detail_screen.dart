import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/external_file_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';

class OutboundDetailScreen extends StatefulWidget {
  final String id;
  const OutboundDetailScreen({super.key, required this.id});
  @override
  State<OutboundDetailScreen> createState() => _OutboundDetailScreenState();
}

class _OutboundDetailScreenState extends State<OutboundDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true, _completing = false;
  bool _isAdmin = false;
  String? _error;
  final Set<String> _pickedDetailIds = {};

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
          title: const Text('Batalkan Outbound'),
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
              child: const Text('Batalkan outbound'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      try {
        final response = await ApiService().cancelOutbound(
          widget.id,
          reason.text.trim(),
        );
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Outbound dibatalkan.'),
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
      final res = await ApiService().getOutboundDetail(widget.id);
      if (!mounted) return;
      setState(() {
        _data = res['data'];
        _loading = false;
        if (_data?['is_complete'] == true ||
            _data?['transaction_status'] == 'cancelled') {
          _pickedDetailIds.clear();
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openDeliveryNote() async {
    try {
      final response = await ApiService().getOutboundDocumentLink(widget.id);
      final url = response['data']['url']?.toString() ?? '';
      await openExternalDocument(url, 'Surat jalan PDF');
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

  Future<void> _completePicking() async {
    final details = (_data?['details'] as List?) ?? [];
    final requiredIds = details
        .map((row) => (row as Map<String, dynamic>)['detail_id'].toString())
        .toSet();
    if (requiredIds.isEmpty || !_pickedDetailIds.containsAll(requiredIds)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Centang seluruh barang yang sudah disiapkan sebelum menyelesaikan picking.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _completing = true);
    try {
      final res = await ApiService().completePicking(
        widget.id,
        requiredIds.toList(),
      );
      if (res['success'] == true) {
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Picking selesai!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _data?['no_shipping'] ?? 'Detail Outbound',
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
    final isComplete = d['is_complete'] == true;
    final priority = d['priority'] ?? 'decent';
    BadgeType bType = priority == 'high'
        ? BadgeType.danger
        : (priority == 'normal' ? BadgeType.warning : BadgeType.success);
    final details = (d['details'] as List?) ?? [];
    final requiredDetailIds = details
        .map((row) => (row as Map<String, dynamic>)['detail_id'].toString())
        .toSet();
    final allPicked =
        requiredDetailIds.isNotEmpty &&
        _pickedDetailIds.containsAll(requiredDetailIds);
    final customer = d['customer'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCancelled) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: .35),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cancel_outlined, color: AppColors.danger),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Transaksi outbound ini telah dibatalkan dan tidak lagi memengaruhi stok.',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Header
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
                            : isComplete
                            ? AppColors.successBg
                            : AppColors.warningBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCancelled
                            ? Icons.cancel_outlined
                            : isComplete
                            ? Icons.check_circle_outline
                            : Icons.pending_actions,
                        size: 18,
                        color: isCancelled
                            ? AppColors.danger
                            : isComplete
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['no_shipping'] ?? '-',
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
                    ),
                    StatusBadge(label: d['priority_label'] ?? '-', type: bType),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                if (customer != null) ...[
                  _row('Customer', customer['nama'] ?? '-'),
                  _row('Kontak', customer['no_kontak'] ?? '-'),
                ],
                _row('Penerima', d['nama_penerima'] ?? '-'),
                _row('Operator', d['operator'] ?? '-'),
                _row(
                  'Status',
                  isCancelled
                      ? 'Dibatalkan'
                      : isComplete
                      ? 'Selesai'
                      : 'Menunggu Picking',
                ),
                if ((d['catatan'] ?? '').toString().isNotEmpty)
                  _row('Catatan', d['catatan'].toString()),

                // Tombol Complete Picking
                if (!isComplete && !isCancelled) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${_pickedDetailIds.length}/${requiredDetailIds.length} barang siap diambil',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: allPicked
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  WmsButton(
                    label: 'Selesaikan Picking',
                    icon: Icons.check_circle_outline,
                    onPressed: allPicked ? _completePicking : null,
                    isLoading: _completing,
                    color: AppColors.success,
                  ),
                ],
                if (isComplete && d['transaction_status'] != 'cancelled') ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _openDeliveryNote,
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Buka Surat Jalan PDF'),
                  ),
                ],
                if (_isAdmin && d['transaction_status'] != 'cancelled') ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _cancel,
                    icon: const Icon(Icons.block),
                    label: const Text('Batalkan Outbound'),
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
          if (!isComplete && !isCancelled) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Ambil dan periksa barang sesuai rak, lalu centang setiap baris. Tombol selesai aktif setelah seluruh barang siap.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
          ],
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
                          if (!isComplete && !isCancelled) ...[
                            Checkbox(
                              value: _pickedDetailIds.contains(
                                det['detail_id'].toString(),
                              ),
                              onChanged: (checked) => setState(() {
                                final detailId = det['detail_id'].toString();
                                if (checked == true) {
                                  _pickedDetailIds.add(detailId);
                                } else {
                                  _pickedDetailIds.remove(detailId);
                                }
                              }),
                            ),
                            const SizedBox(width: 4),
                          ] else ...[
                            Icon(
                              isComplete
                                  ? Icons.check_circle
                                  : Icons.cancel_outlined,
                              color: isComplete
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                            const SizedBox(width: 12),
                          ],
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
                              ],
                            ),
                          ),
                          Text(
                            '-${det['qty']} ${det['satuan'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.danger,
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
