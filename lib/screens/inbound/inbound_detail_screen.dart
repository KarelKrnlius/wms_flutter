import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class InboundDetailScreen extends StatefulWidget {
  final int id;
  const InboundDetailScreen({super.key, required this.id});
  @override
  State<InboundDetailScreen> createState() => _InboundDetailScreenState();
}

class _InboundDetailScreenState extends State<InboundDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService().getInboundDetail(widget.id);
      setState(() { _data = res['data']; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_data?['no_receiving'] ?? 'Detail Inbound', style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
        backgroundColor: AppColors.surface,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: _loading ? const LoadingView() : _error != null ? ErrorView(message: _error!, onRetry: _load) : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _data!;
    final details = (d['details'] as List?) ?? [];
    final supplier = d['supplier'] as Map<String, dynamic>?;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WmsCard(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.arrow_downward_rounded, size: 18, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['no_receiving'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                Text(d['tanggal'] ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ]),
            ]),
            const SizedBox(height: 12), const Divider(), const SizedBox(height: 8),
            if (supplier != null) ...[_row('Supplier', supplier['nama'] ?? '-'), _row('Kontak', supplier['no_kontak'] ?? '-')],
            _row('Operator', d['operator'] ?? '-'),
            if ((d['catatan'] ?? '').toString().isNotEmpty) _row('Catatan', d['catatan'].toString()),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Detail Barang (${details.length} item)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        WmsCard(child: Column(children: details.asMap().entries.map((e) {
          final det = e.value as Map<String, dynamic>;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(det['nama_barang'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(det['sku'] ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontFamily: 'monospace')),
                  const SizedBox(height: 4),
                  StatusBadge(label: 'Rak: ${det['rack'] ?? '-'}', type: BadgeType.neutral),
                ])),
                Text('+${det['qty']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success)),
              ]),
            ),
            if (e.key < details.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
          ]);
        }).toList())),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
      const Text(': ', style: TextStyle(color: AppColors.textHint)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
    ]),
  );
}
