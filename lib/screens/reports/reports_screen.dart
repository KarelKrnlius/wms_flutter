import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import '../../services/api_service.dart';
import '../../services/external_file_service.dart';
import '../../widgets/common_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = false;

  Future<void> _download(String type) async {
    setState(() => _loading = true);
    try {
      final response = await ApiService().getReportLinks();
      final url = (response['data'] as Map<String, dynamic>)[type]?.toString();
      if (url == null || url.isEmpty) {
        throw Exception('Tautan laporan tidak diberikan oleh server.');
      }
      await openExternalDocument(url, 'File Excel');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reports = [
      (
        'inventory',
        'Laporan Inventori',
        'Stok fisik, reservasi, tersedia, satuan, harga, dan nilai barang.',
        Icons.inventory_2_outlined,
        AppColors.primary,
      ),
      (
        'inbound',
        'Laporan Inbound',
        'Riwayat penerimaan barang dan nilai transaksi.',
        Icons.move_to_inbox_outlined,
        AppColors.success,
      ),
      (
        'outbound',
        'Laporan Outbound',
        'Riwayat pengiriman, customer, dan status picking.',
        Icons.outbox_outlined,
        AppColors.warning,
      ),
    ];
    return GridView.builder(
      padding: context.pagePadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.isDesktop
            ? 3
            : context.isTablet
            ? 2
            : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: context.isMobile ? 1.9 : 1.35,
      ),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return WmsCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: report.$5.withValues(alpha: .12),
                foregroundColor: report.$5,
                child: Icon(report.$4),
              ),
              const SizedBox(height: 14),
              Text(
                report.$2,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Text(
                  report.$3,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _loading ? null : () => _download(report.$1),
                icon: const Icon(Icons.download),
                label: const Text('Export Excel'),
              ),
            ],
          ),
        );
      },
    );
  }
}
