import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'inbound_detail_screen.dart';
import 'create_inbound_screen.dart';

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
  final _search = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _load(reset: true, showLoading: false),
    );
  }

  Future<void> _load({bool reset = false, bool showLoading = true}) async {
    if (reset) {
      _page = 1;
      if (showLoading) {
        setState(() => _loading = true);
      }
      setState(() => _error = null);
    }
    try {
      final res = await ApiService().getInbound(
        page: _page,
        search: _search.text,
      );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateInboundScreen()),
          );
          if (changed == true) _load(reset: true);
        },
        icon: const Icon(Icons.add),
        label: const Text('Buat Inbound'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: () => _load(reset: true));
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount:
            1 +
            (_items.isEmpty ? 1 : _items.length + (_page < _lastPage ? 1 : 0)),
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextField(
                controller: _search,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari No. RSI / Supplier...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _search.clear();
                            _load(reset: true, showLoading: false);
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            );
          }
          i--;
          if (_items.isEmpty) {
            return EmptyView(
              message: _search.text.trim().isEmpty
                  ? 'Belum ada transaksi inbound'
                  : 'No. RSI atau supplier tidak ditemukan',
              icon: Icons.search_off,
            );
          }
          if (i == _items.length) {
            return TextButton(
              onPressed: () {
                _page++;
                _load();
              },
              child: const Text('Muat lebih banyak...'),
            );
          }
          final trx = _items[i] as Map<String, dynamic>;
          final isCancelled = trx['transaction_status'] == 'cancelled';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        InboundDetailScreen(id: trx['inbound_id'].toString()),
                  ),
                );
                if (mounted) _load(reset: true, showLoading: false);
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
                            : AppColors.successBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isCancelled
                            ? Icons.cancel_outlined
                            : Icons.arrow_downward_rounded,
                        size: 20,
                        color: isCancelled
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trx['no_receiving'] ?? '-',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            trx['supplier'] ?? '-',
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
                                label: '${trx['total_qty']} unit',
                                type: isCancelled
                                    ? BadgeType.neutral
                                    : BadgeType.success,
                              ),
                              StatusBadge(
                                label: isCancelled ? 'Dibatalkan' : 'Berhasil',
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
    );
  }
}
