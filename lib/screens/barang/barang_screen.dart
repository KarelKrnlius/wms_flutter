import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'barang_detail_screen.dart';

/// BarangScreen - Daftar Master Data Barang dengan search & filter kategori

class BarangScreen extends StatefulWidget {
  const BarangScreen({super.key});

  @override
  State<BarangScreen> createState() => _BarangScreenState();
}

class _BarangScreenState extends State<BarangScreen> {
  List<dynamic> _items = [];
  List<String> _kategori = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String _search = '';
  String? _selectedKategori;
  int _currentPage = 1;
  int _lastPage = 1;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKategori();
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKategori() async {
    try {
      final res = await ApiService().getKategori();
      if (res['success'] == true) {
        setState(() => _kategori = List<String>.from(res['data'] ?? []));
      }
    } catch (_) {}
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final res = await ApiService().getBarang(
        search: _search.isEmpty ? null : _search,
        kategori: _selectedKategori,
        page: _currentPage,
        perPage: 20,
      );

      final newItems = res['data'] as List? ?? [];
      final meta = res['meta'] as Map<String, dynamic>? ?? {};

      setState(() {
        if (reset) {
          _items = newItems;
        } else {
          _items.addAll(newItems);
        }
        _lastPage = meta['last_page'] ?? 1;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onSearch(String v) {
    _search = v;
    _load(reset: true);
  }

  void _onKategori(String? v) {
    _selectedKategori = v;
    _load(reset: true);
  }

  Color _stokColor(String status) {
    switch (status) {
      case 'Habis':
        return AppColors.danger;
      case 'Reorder':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  BadgeType _stokBadge(String status) {
    switch (status) {
      case 'Habis':
        return BadgeType.danger;
      case 'Reorder':
        return BadgeType.warning;
      default:
        return BadgeType.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ---- SEARCH & FILTER ----
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Cari SKU, nama, kategori...',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
              if (_kategori.isNotEmpty) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _KategoriChip(
                        label: 'Semua',
                        selected: _selectedKategori == null,
                        onTap: () => _onKategori(null),
                      ),
                      ..._kategori.map(
                        (k) => _KategoriChip(
                          label: k,
                          selected: _selectedKategori == k,
                          onTap: () => _onKategori(k),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),

        // ---- CONTENT ----
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
              ? ErrorView(message: _error!, onRetry: () => _load(reset: true))
              : _items.isEmpty
              ? const EmptyView(
                  message: 'Tidak ada barang ditemukan',
                  icon: Icons.inventory_2_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount:
                      _items.length +
                      (_loadingMore ? 1 : 0) +
                      (_currentPage < _lastPage && !_loadingMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == _items.length && _loadingMore) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }
                    if (i == _items.length && _currentPage < _lastPage) {
                      return TextButton(
                        onPressed: () {
                          _currentPage++;
                          _load();
                        },
                        child: const Text('Muat lebih banyak...'),
                      );
                    }
                    final item = _items[i] as Map<String, dynamic>;
                    final status = item['status_stok'] ?? 'Aman';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BarangDetailScreen(sku: item['sku']),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: WmsCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLow,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['nama'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['sku'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        StatusBadge(
                                          label: item['kategori'] ?? '-',
                                          type: BadgeType.neutral,
                                        ),
                                        StatusBadge(
                                          label: status,
                                          type: _stokBadge(status),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Stok
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item['stok'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: _stokColor(status),
                                    ),
                                  ),
                                  Text(
                                    item['satuan'] ?? 'PCS',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
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
      ],
    );
  }
}

class _KategoriChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _KategoriChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
