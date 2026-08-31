import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'outbound_detail_screen.dart';

class OutboundScreen extends StatefulWidget {
  const OutboundScreen({super.key});
  @override
  State<OutboundScreen> createState() => _OutboundScreenState();
}

class _OutboundScreenState extends State<OutboundScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _queue = [], _riwayat = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final qRes = await ApiService().getOutbound(status: 'not_complete');
      final rRes = await ApiService().getOutbound(status: 'complete');
      setState(() {
        _queue   = (qRes['data'] as List?) ?? [];
        _riwayat = (rRes['data'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: AppColors.surface,
        child: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Picking Queue (${_loading ? '...' : _queue.length})'),
            Tab(text: 'Riwayat (${_loading ? '...' : _riwayat.length})'),
          ],
        ),
      ),
      Expanded(child: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : TabBarView(controller: _tab, children: [
                  _buildList(_queue, isPicking: true),
                  _buildList(_riwayat, isPicking: false),
                ])),
    ]);
  }

  Widget _buildList(List<dynamic> items, {required bool isPicking}) {
    if (items.isEmpty) {
      return EmptyView(
        message: isPicking ? 'Tidak ada picking yang pending' : 'Belum ada riwayat outbound',
        icon: Icons.arrow_upward_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final trx = items[i] as Map<String, dynamic>;
          final priority = trx['priority'] ?? 'decent';
          BadgeType bType = priority == 'high' ? BadgeType.danger : (priority == 'normal' ? BadgeType.warning : BadgeType.success);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OutboundDetailScreen(id: trx['outbound_id']))),
              borderRadius: BorderRadius.circular(12),
              child: WmsCard(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: isPicking ? AppColors.warningBg : AppColors.successBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(isPicking ? Icons.pending_actions : Icons.check_circle_outline,
                        size: 20, color: isPicking ? AppColors.warning : AppColors.success),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(trx['no_shipping'] ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: AppColors.textPrimary)),
                    Text(trx['customer'] ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Row(children: [
                      StatusBadge(label: trx['tanggal'] ?? '-', type: BadgeType.neutral),
                      const SizedBox(width: 6),
                      StatusBadge(label: trx['priority_label'] ?? '-', type: bType),
                      const SizedBox(width: 6),
                      StatusBadge(label: '${trx['total_qty']} unit', type: BadgeType.primary),
                    ]),
                  ])),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
