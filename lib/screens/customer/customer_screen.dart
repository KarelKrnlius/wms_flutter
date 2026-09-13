import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

/// CustomerScreen - Direktori Customer (Read-Only)
/// Meniru tampilan web: Nama, No.Telepon, Email, Alamat, Total Outbound
/// - Icon: store (slate)
/// - Badge total: amber (badge-warning) sesuai web

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});
  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  int _total = 0;

  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService().getCustomers(
        search: _search.isEmpty ? null : _search,
      );
      final data = (res['data'] as List?) ?? [];
      final meta = (res['meta'] as Map<String, dynamic>?) ?? {};
      setState(() {
        _items  = data;
        _total  = meta['total'] ?? data.length;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _onSearch(String v) {
    _search = v;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ---- HEADER ----
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner (meniru web)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Master Data Customer (Read-Only Directory)',
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Direktori Customer bersifat Read-Only. Data bertambah otomatis saat transaksi Outbound dibuat.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Header title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.storefront, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daftar Pelanggan (Customer)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text('Seluruh entitas customer yang tercatat dari transaksi outbound.',
                            style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Search
              Material(
                color: Colors.transparent,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cari nama / kontak / alamat...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textHint),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ---- TOTAL BAR ----
        if (!_loading)
          Container(
            color: AppColors.surfaceLow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.storefront, size: 13, color: AppColors.textHint),
                const SizedBox(width: 6),
                Text(
                  '$_total customer terdaftar',
                  style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

        // ---- CONTENT ----
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _items.isEmpty
                      ? EmptyView(
                          message: _search.isNotEmpty
                              ? 'Tidak ada customer dengan kata kunci "$_search"'
                              : 'Belum ada data customer yang tercatat dari proses Outbound.',
                          icon: Icons.storefront_outlined,
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            itemBuilder: (ctx, i) {
                              final c = _items[i] as Map<String, dynamic>;
                              return _CustomerCard(customer: c);
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final total = customer['total_transaksi'] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WmsCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris atas: icon store + nama + badge total outbound (amber sesuai web badge-warning)
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront, size: 20, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    customer['nama'] ?? '-',
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                    ),
                  ),
                ),
                // badge-warning = amber (sesuai web)
                _OutboundBadge(count: total),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Kolom sesuai web: Telepon, Email, Alamat
            _infoRow(Icons.phone_outlined, 'Telepon',
                _str(customer['no_kontak'])),
            const SizedBox(height: 6),
            _infoRow(Icons.email_outlined, 'Email',
                _str(customer['email'])),
            const SizedBox(height: 6),
            _infoRow(Icons.location_on_outlined, 'Alamat',
                _str(customer['alamat'])),
          ],
        ),
      ),
    );
  }

  String _str(dynamic v) =>
      (v != null && v.toString().isNotEmpty) ? v.toString() : '-';

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ),
        const Text(': ', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
              )),
        ),
      ],
    );
  }
}

/// Badge amber (badge-warning) untuk total outbound — sesuai web
class _OutboundBadge extends StatelessWidget {
  final int count;
  const _OutboundBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // badge-warning di web: amber muda
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_upward, size: 10, color: Color(0xFF92400E)),
          const SizedBox(width: 4),
          Text(
            '$count transaksi',
            style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }
}
