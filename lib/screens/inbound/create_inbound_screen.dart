import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import '../shared/quick_party_dialog.dart';

class CreateInboundScreen extends StatefulWidget {
  const CreateInboundScreen({super.key});
  @override
  State<CreateInboundScreen> createState() => _CreateInboundScreenState();
}

class _CreateInboundScreenState extends State<CreateInboundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  String? _supplierId, _error;
  List<dynamic> _suppliers = [], _items = [], _racks = [], _units = [];
  final List<_InboundLine> _lines = [_InboundLine()];
  bool _loading = true, _saving = false;

  Map<String, dynamic>? _selectedItem(_InboundLine line) {
    for (final raw in _items) {
      final item = raw as Map<String, dynamic>;
      if (item['sku'] == line.sku) return item;
    }
    return null;
  }

  int _linePrice(_InboundLine line) => line.isNew
      ? int.tryParse(line.price.text) ?? 0
      : (_selectedItem(line)?['harga_dasar'] as num?)?.toInt() ?? 0;

  int get _grandTotal => _lines.fold(
    0,
    (total, line) =>
        total + _linePrice(line) * (int.tryParse(line.qty.text) ?? 0),
  );

  String _rupiah(int value) =>
      'Rp ${NumberFormat('#,###', 'id_ID').format(value)}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await ApiService().getInboundFormOptions();
      final data = response['data'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _suppliers = data['suppliers'] ?? [];
        _items = data['items'] ?? [];
        _racks = data['racks'] ?? [];
        _units = data['units'] ?? [];
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _addSupplier() async {
    final row = await showQuickPartyDialog(context, supplier: true);
    if (row == null || !mounted) return;
    setState(() {
      _suppliers = [..._suppliers, row];
      _supplierId = row['id'].toString();
    });
  }

  Future<void> _addUnit(_InboundLine line) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah Satuan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama satuan',
            hintText: 'Contoh: PCS, BOX, KG',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || !mounted) return;
    try {
      final response = await ApiService().createUnit(name.trim());
      final value = response['data']['nama'].toString();
      if (!mounted) return;
      setState(() {
        if (!_units.contains(value)) _units = [..._units, value];
        line.unit = value;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await ApiService().createInbound({
        'Tanggal': DateFormat('yyyy-MM-dd').format(_date),
        'Supplier_ID': _supplierId,
        'Catatan': _notes.text.trim(),
        'items': _lines.map((line) => line.payload).toList(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Inbound berhasil dibuat.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Buat Inbound')),
    body: _loading
        ? const LoadingView()
        : _error != null && _suppliers.isEmpty
        ? ErrorView(message: _error!, onRetry: _load)
        : Form(
            key: _formKey,
            child: ListView(
              padding: context.pagePadding,
              children: [
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                WmsCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _supplierId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Supplier',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        items: _suppliers
                            .map<DropdownMenuItem<String>>(
                              (row) => DropdownMenuItem(
                                value: row['id'].toString(),
                                child: Text(row['nama'] ?? '-'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _supplierId = value),
                        validator: (value) =>
                            value == null ? 'Supplier wajib dipilih' : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _addSupplier,
                          icon: const Icon(Icons.add_business, size: 18),
                          label: const Text('Supplier baru'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Tanggal penerimaan',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          hintText: DateFormat(
                            'dd MMMM yyyy',
                            'id_ID',
                          ).format(_date),
                        ),
                        onTap: () async {
                          final value = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDate: _date,
                          );
                          if (value != null) setState(() => _date = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notes,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Barang Diterima',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _lines.add(_InboundLine())),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah barang'),
                    ),
                  ],
                ),
                ...List.generate(_lines.length, _lineCard),
                const SizedBox(height: 12),
                WmsCard(
                  padding: const EdgeInsets.all(18),
                  child: context.isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Nilai Inbound',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _rupiah(_grandTotal),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total Nilai Inbound',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Text(
                              _rupiah(_grandTotal),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Simpan Inbound'),
                ),
              ],
            ),
          ),
  );

  Widget _lineCard(int index) {
    final line = _lines[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WmsCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Barang #${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (!context.isMobile)
                  SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Barang Lama')),
                    ButtonSegment(value: true, label: Text('Barang Baru')),
                  ],
                  selected: {line.isNew},
                  onSelectionChanged: (value) =>
                      setState(() => line.isNew = value.first),
                  ),
                if (_lines.length > 1)
                  IconButton(
                    onPressed: () => setState(() {
                      _lines.removeAt(index).dispose();
                    }),
                    icon: const Icon(Icons.close, color: AppColors.danger),
                  ),
              ],
            ),
            if (context.isMobile) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, label: Text('Barang Lama')),
                    ButtonSegment(value: true, label: Text('Barang Baru')),
                  ],
                  selected: {line.isNew},
                  onSelectionChanged: (value) =>
                      setState(() => line.isNew = value.first),
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (!line.isNew)
              DropdownButtonFormField<String>(
                initialValue: line.sku,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Barang / SKU'),
                items: _items
                    .map<DropdownMenuItem<String>>(
                      (row) => DropdownMenuItem(
                        value: row['sku'],
                        child: Text(
                          '${row['sku']} — ${row['nama']} • ${row['satuan']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => line.sku = value),
                validator: (value) =>
                    line.isNew || value != null ? null : 'Barang wajib dipilih',
              )
            else ...[
              TextFormField(
                controller: line.name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama barang baru',
                ),
                validator: (value) =>
                    !line.isNew || (value?.trim().isNotEmpty ?? false)
                    ? null
                    : 'Nama wajib diisi',
              ),
              const SizedBox(height: 10),
              Flex(
                direction: context.isMobile ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _mobileField(
                    TextFormField(
                      controller: line.category,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      validator: (value) =>
                          !line.isNew || (value?.trim().isNotEmpty ?? false)
                          ? null
                          : 'Kategori wajib diisi',
                    ),
                  ),
                  SizedBox(
                    width: context.isMobile ? 0 : 10,
                    height: context.isMobile ? 10 : 0,
                  ),
                  _mobileField(
                    DropdownButtonFormField<String>(
                      initialValue: line.unit,
                      decoration: const InputDecoration(labelText: 'Satuan'),
                      items: _units
                          .map<DropdownMenuItem<String>>(
                            (value) => DropdownMenuItem(
                              value: value.toString(),
                              child: Text(value.toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => line.unit = value),
                      validator: (value) => !line.isNew || value != null
                          ? null
                          : 'Satuan wajib dipilih',
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => _addUnit(line),
                      tooltip: 'Tambah satuan',
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flex(
                direction: context.isMobile ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _mobileField(
                    TextFormField(
                      controller: line.price,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Harga dasar',
                      ),
                      validator: (value) =>
                          !line.isNew || (int.tryParse(value ?? '') ?? -1) >= 0
                          ? null
                          : 'Harga tidak valid',
                    ),
                  ),
                  SizedBox(
                    width: context.isMobile ? 0 : 10,
                    height: context.isMobile ? 10 : 0,
                  ),
                  _mobileField(
                    TextFormField(
                      controller: line.minimum,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minimum stok',
                      ),
                      validator: (value) =>
                          !line.isNew || (int.tryParse(value ?? '') ?? -1) >= 0
                          ? null
                          : 'Minimum tidak valid',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Flex(
              direction: context.isMobile ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _mobileField(
                  DropdownButtonFormField<String>(
                    initialValue: line.rackId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Rak tujuan'),
                    items: _racks
                        .map<DropdownMenuItem<String>>(
                          (row) => DropdownMenuItem(
                            value: row['id'].toString(),
                            child: Text(
                              '${row['kode_rak']} • sisa ${row['sisa']}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => line.rackId = value),
                    validator: (value) =>
                        value == null ? 'Rak wajib dipilih' : null,
                  ),
                ),
                SizedBox(
                  width: context.isMobile ? 0 : 10,
                  height: context.isMobile ? 10 : 0,
                ),
                _mobileField(
                  TextFormField(
                    controller: line.qty,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Qty'),
                    validator: (value) => (int.tryParse(value ?? '') ?? 0) > 0
                        ? null
                        : 'Qty minimal 1',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!line.isNew && line.sku != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: context.isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Harga tersimpan: ${_rupiah(_linePrice(line))} / ${_selectedItem(line)?['satuan'] ?? '-'}",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Subtotal ${_rupiah(_linePrice(line) * (int.tryParse(line.qty.text) ?? 0))}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      )
                    : Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Harga tersimpan: ${_rupiah(_linePrice(line))} / ${_selectedItem(line)?['satuan'] ?? '-'}",
                      ),
                    ),
                    Text(
                      'Subtotal ${_rupiah(_linePrice(line) * (int.tryParse(line.qty.text) ?? 0))}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ] else if (line.isNew) ...[
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Subtotal ${_rupiah(_linePrice(line) * (int.tryParse(line.qty.text) ?? 0))}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextFormField(
              controller: line.receipt,
              enabled: !line.noReceipt,
              decoration: InputDecoration(
                labelText: line.noReceipt
                    ? 'Resi dinyatakan tidak ada'
                    : 'No. resi supplier',
              ),
              validator: (value) =>
                  !line.noReceipt && (value?.trim().isEmpty ?? true)
                  ? 'Isi nomor resi atau pilih Tidak ada resi'
                  : null,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: line.noReceipt,
              title: const Text('Tidak ada resi'),
              subtitle: const Text(
                'Pilih hanya jika barang memang tidak memiliki resi supplier.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) => setState(() {
                line.noReceipt = value ?? false;
                if (line.noReceipt) line.receipt.clear();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileField(Widget child) =>
      context.isMobile ? child : Expanded(child: child);
}

class _InboundLine {
  bool isNew = false;
  bool noReceipt = false;
  String? sku, rackId, unit;
  final qty = TextEditingController(text: '1');
  final name = TextEditingController(),
      category = TextEditingController(),
      price = TextEditingController(),
      minimum = TextEditingController(text: '0'),
      receipt = TextEditingController();
  Map<String, dynamic> get payload => {
    'jenis': isNew ? 'baru' : 'lama',
    'Qty': int.parse(qty.text),
    'No_Resi_Supplier': receipt.text.trim(),
    'tanpa_resi': noReceipt,
    if (isNew) ...{
      'Nama_baru': name.text.trim(),
      'Kategori_baru': category.text.trim(),
      'Satuan_baru': unit,
      'Rack_ID_baru': rackId,
      'Min_Stok_baru': int.parse(minimum.text),
      'Harga_Satuan': int.parse(price.text),
    } else ...{
      'SKU_lama': sku,
      'Rack_ID_lama': rackId,
    },
  };
  void dispose() {
    qty.dispose();
    name.dispose();
    category.dispose();
    price.dispose();
    minimum.dispose();
    receipt.dispose();
  }
}
