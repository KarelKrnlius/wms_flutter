import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'inbound_detail_screen.dart';

class InboundScreen extends StatefulWidget {
  const InboundScreen({super.key});
  @override
  State<InboundScreen> createState() => _InboundScreenState();
}

class _InboundScreenState extends State<InboundScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  int _page = 1, _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _page = 1;
      setState(() { _loading = true; _error = null; });
    }
    try {
      final res = await ApiService().getInbound(page: _page);
      final newItems = (res['data'] as List?) ?? [];
      final meta = (res['meta'] as Map<String, dynamic>?) ?? {};
      setState(() {
        if (reset) {
          _items = newItems;
        } else {
          _items.addAll(newItems);
        }
        _lastPage = meta['last_page'] ?? 1;
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
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: () => _load(reset: true));
    if (_items.isEmpty) {
      return const EmptyView(
        message: 'Belum ada transaksi inbound',
        icon: Icons.arrow_downward_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + (_page < _lastPage ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == _items.length) {
            return TextButton(
              onPressed: () { _page++; _load(); },
              child: const Text('Muat lebih banyak...'),
            );
          }
          final trx = _items[i] as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InboundDetailScreen(id: trx['inbound_id'])),
              ),
              borderRadius: BorderRadius.circular(12),
              child: WmsCard(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_downward_rounded, size: 20, color: AppColors.success),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(trx['no_receiving'] ?? '-',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              fontFamily: 'monospace', color: AppColors.textPrimary)),
                      Text(trx['supplier'] ?? '-',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Row(children: [
                        StatusBadge(label: trx['tanggal'] ?? '-', type: BadgeType.neutral),
                        const SizedBox(width: 6),
                        StatusBadge(label: '${trx['total_qty']} unit', type: BadgeType.success),
                      ]),
                    ]),
                  ),
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
