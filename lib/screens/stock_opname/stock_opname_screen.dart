import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class StockOpnameScreen extends StatefulWidget {
  const StockOpnameScreen({super.key});
  @override
  State<StockOpnameScreen> createState() => _StockOpnameScreenState();
}

class _StockOpnameScreenState extends State<StockOpnameScreen> {
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
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final res = await ApiService().getStockOpname(page: _page);
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
          final refresh = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const _TambahOpnameScreen()),
          );
          if (refresh == true) _load(reset: true);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Opname',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(message: _error!, onRetry: () => _load(reset: true))
          : _items.isEmpty
          ? const EmptyView(
              message: 'Belum ada catatan stock opname',
              icon: Icons.assignment_outlined,
            )
          : RefreshIndicator(
              onRefresh: () => _load(reset: true),
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _items.length + (_page < _lastPage ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == _items.length) {
                    return TextButton(
                      onPressed: () {
                        _page++;
                        _load();
                      },
                      child: const Text('Muat lebih banyak...'),
                    );
                  }
                  final op = _items[i] as Map<String, dynamic>;
                  return _OpnameCard(opname: op);
                },
              ),
            ),
    );
  }
}

class _OpnameCard extends StatelessWidget {
  final Map<String, dynamic> opname;
  const _OpnameCard({required this.opname});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WmsCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fact_check_outlined,
                    size: 18,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opname['nama_barang'] ?? '-',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        opname['sku'] ?? '-',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(
                      label: opname['tanggal'] ?? '-',
                      type: BadgeType.neutral,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opname['operator'] ?? '-',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 13, color: AppColors.textHint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    opname['kondisi'] ?? '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---- TAMBAH OPNAME ----
class _TambahOpnameScreen extends StatefulWidget {
  const _TambahOpnameScreen();
  @override
  State<_TambahOpnameScreen> createState() => _TambahOpnameScreenState();
}

class _TambahOpnameScreenState extends State<_TambahOpnameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kondisiCtrl = TextEditingController();

  List<dynamic> _barangs = [];
  String? _selectedSku;
  DateTime _tanggal = DateTime.now();
  bool _loading = false, _loadingBarang = true;

  @override
  void initState() {
    super.initState();
    _loadBarang();
  }

  @override
  void dispose() {
    _kondisiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBarang() async {
    try {
      final res = await ApiService().getKartuStok();
      setState(() {
        _barangs = (res['data'] as List?) ?? [];
        _loadingBarang = false;
      });
    } catch (_) {
      setState(() => _loadingBarang = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSku == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih barang terlebih dahulu'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final tanggalStr =
          '${_tanggal.year}-${_tanggal.month.toString().padLeft(2, '0')}-${_tanggal.day.toString().padLeft(2, '0')}';
      await ApiService().createStockOpname({
        'SKU': _selectedSku,
        'Tanggal': tanggalStr,
        'Kondisi': _kondisiCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock Opname berhasil disimpan'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tambah Stock Opname',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingBarang
          ? const LoadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: WmsCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Barang *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.surface,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSku,
                            isExpanded: true,
                            hint: const Text(
                              'Pilih barang...',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textHint,
                              ),
                            ),
                            items: _barangs.map((b) {
                              final sku = b['sku'] as String;
                              final nama = b['nama'] as String;
                              return DropdownMenuItem(
                                value: sku,
                                child: Text(
                                  '$sku — $nama',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedSku = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tanggal Opname *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.surface,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_tanggal.day.toString().padLeft(2, '0')}/${_tanggal.month.toString().padLeft(2, '0')}/${_tanggal.year}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Deskripsi Kondisi Fisik *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _kondisiCtrl,
                        maxLines: 4,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Kondisi wajib diisi';
                          }
                          if (v.trim().length < 5) return 'Minimal 5 karakter';
                          return null;
                        },
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText:
                              'Contoh: Kondisi barang baik, kemasan utuh.',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                      ),
                      const SizedBox(height: 20),
                      WmsButton(
                        label: 'Simpan Catatan Opname',
                        icon: Icons.save_outlined,
                        onPressed: _submit,
                        isLoading: _loading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
