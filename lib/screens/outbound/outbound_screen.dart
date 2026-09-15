import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'outbound_detail_screen.dart';
import 'create_outbound_screen.dart';

class OutboundScreen extends StatefulWidget {
  const OutboundScreen({super.key});
  @override
  State<OutboundScreen> createState() => _OutboundScreenState();
}

class _OutboundScreenState extends State<OutboundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _queue = [], _riwayat = [];
  bool _loading = true;
  String? _error;
  final _queueSearch = TextEditingController();
  final _historySearch = TextEditingController();
  Timer? _queueDebounce, _historyDebounce;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _queueDebounce?.cancel();
    _historyDebounce?.cancel();
    _queueSearch.dispose();
    _historySearch.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    setState(() {
      if (showLoading) _loading = true;
      _error = null;
    });
    try {
      final qRes = await ApiService().getOutbound(
        status: 'not_complete',
        search: _queueSearch.text,
      );
      final rRes = await ApiService().getOutbound(
        status: 'complete',
        search: _historySearch.text,
      );
      setState(() {
        _queue = (qRes['data'] as List?) ?? [];
        _riwayat = (rRes['data'] as List?) ?? [];
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateOutboundScreen(),
                  ),
                );
                if (changed == true) _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('Buat Outbound'),
            ),
          ),
        ),
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
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tab,
                  children: [
                    _buildList(_queue, isPicking: true),
                    _buildList(_riwayat, isPicking: false),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildList(List<dynamic> items, {required bool isPicking}) {
    final controller = isPicking ? _queueSearch : _historySearch;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: TextField(
            controller: controller,
            onChanged: (_) {
              final timer = Timer(
                const Duration(milliseconds: 350),
                () => _load(showLoading: false),
              );
              if (isPicking) {
                _queueDebounce?.cancel();
                _queueDebounce = timer;
              } else {
                _historyDebounce?.cancel();
                _historyDebounce = timer;
              }
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Cari No. SJ / Customer...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        controller.clear();
                        _load(showLoading: false);
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? EmptyView(
                  message: controller.text.trim().isNotEmpty
                      ? 'No. SJ atau customer tidak ditemukan'
                      : isPicking
                      ? 'Tidak ada picking yang pending'
                      : 'Belum ada riwayat outbound',
                  icon: controller.text.trim().isNotEmpty
                      ? Icons.search_off
                      : Icons.arrow_upward_rounded,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final trx = items[i] as Map<String, dynamic>;
                      final isCancelled =
                          trx['transaction_status'] == 'cancelled';
                      final priority = trx['priority'] ?? 'decent';
                      BadgeType bType = priority == 'high'
                          ? BadgeType.danger
                          : (priority == 'normal'
                                ? BadgeType.warning
                                : BadgeType.success);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OutboundDetailScreen(
                                  id: trx['outbound_id'].toString(),
                                ),
                              ),
                            );
                            if (mounted) _load(showLoading: false);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: WmsCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isCancelled
                                        ? AppColors.dangerBg
                                        : isPicking
                                        ? AppColors.warningBg
                                        : AppColors.successBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isCancelled
                                        ? Icons.cancel_outlined
                                        : isPicking
                                        ? Icons.pending_actions
                                        : Icons.check_circle_outline,
                                    size: 20,
                                    color: isCancelled
                                        ? AppColors.danger
                                        : isPicking
                                        ? AppColors.warning
                                        : AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        trx['no_shipping'] ?? '-',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'monospace',
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        trx['customer'] ?? '-',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          StatusBadge(
                                            label: trx['tanggal'] ?? '-',
                                            type: BadgeType.neutral,
                                          ),
                                          StatusBadge(
                                            label: trx['priority_label'] ?? '-',
                                            type: bType,
                                          ),
                                          StatusBadge(
                                            label: '${trx['total_qty']} unit',
                                            type: BadgeType.primary,
                                          ),
                                          StatusBadge(
                                            label: isCancelled
                                                ? 'Dibatalkan'
                                                : 'Berhasil',
                                            type: isCancelled
                                                ? BadgeType.danger
                                                : BadgeType.success,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: AppColors.textHint,
                                ),
                              ],
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
