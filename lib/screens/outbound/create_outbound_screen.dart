import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import '../shared/quick_party_dialog.dart';

class CreateOutboundScreen extends StatefulWidget {
  const CreateOutboundScreen({super.key});

  @override
  State<CreateOutboundScreen> createState() => _CreateOutboundScreenState();
}

class _CreateOutboundScreenState extends State<CreateOutboundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipient = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  String? _customerId;
  List<dynamic> _customers = [], _availableItems = [];
  final List<_OutboundLine> _lines = [_OutboundLine()];
  bool _loading = true, _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _recipient.dispose();
    _notes.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await ApiService().getOutboundFormOptions();
      final data = response['data'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _customers = data['customers'] ?? [];
        _availableItems = data['items'] ?? [];
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

  Future<void> _addCustomer() async {
    final row = await showQuickPartyDialog(context, supplier: false);
    if (row == null || !mounted) return;
    setState(() {
      _customers = [..._customers, row];
      _customerId = row['id'].toString();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final skus = _lines.map((line) => line.sku).whereType<String>().toList();
    if (skus.toSet().length != skus.length) {
      setState(
        () => _error =
            'Barang yang sama cukup ditulis satu kali. Ubah Qty pada baris tersebut.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await ApiService().createOutbound({
        'Tanggal': DateFormat('yyyy-MM-dd').format(_date),
        'Customer_ID': _customerId,
        'Nama_Penerima': _recipient.text.trim(),
        'Catatan': _notes.text.trim(),
        'items': _lines
            .map((line) => {'SKU': line.sku, 'Qty': int.parse(line.qty.text)})
            .toList(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Outbound berhasil dibuat.'),
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
    appBar: AppBar(title: const Text('Buat Outbound')),
    body: _loading
        ? const LoadingView()
        : _error != null && _customers.isEmpty
        ? ErrorView(message: _error!, onRetry: _load)
        : Form(
            key: _formKey,
            child: ListView(
              padding: context.pagePadding,
              children: [
                if (_error != null) _ErrorBanner(_error!),
                WmsCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _customerId,
                        decoration: const InputDecoration(
                          labelText: 'Customer',
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        items: _customers
                            .map<DropdownMenuItem<String>>(
                              (row) => DropdownMenuItem(
                                value: row['id'].toString(),
                                child: Text(row['nama'] ?? '-'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _customerId = value),
                        validator: (value) =>
                            value == null ? 'Customer wajib dipilih' : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _addCustomer,
                          icon: const Icon(Icons.person_add_alt, size: 18),
                          label: const Text('Customer baru'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _recipient,
                        decoration: const InputDecoration(
                          labelText: 'Nama penerima',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Tanggal',
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
                        'Barang Keluar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _lines.add(_OutboundLine())),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah barang'),
                    ),
                  ],
                ),
                ...List.generate(_lines.length, (index) => _lineCard(index)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Simpan Outbound'),
                ),
              ],
            ),
          ),
  );

  Widget _lineCard(int index) {
    final line = _lines[index];
    final matches = _availableItems.where((row) => row['sku'] == line.sku);
    final selected = matches.isEmpty ? null : matches.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WmsCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Barang #${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (_lines.length > 1)
                  IconButton(
                    onPressed: () => setState(() {
                      _lines.removeAt(index).dispose();
                    }),
                    icon: const Icon(Icons.close, color: AppColors.danger),
                  ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: line.sku,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Barang / SKU'),
              items: _availableItems
                  .map<DropdownMenuItem<String>>(
                    (row) => DropdownMenuItem(
                      value: row['sku'],
                      child: Text(
                        '${row['sku']} — ${row['nama']} (${row['stok']} ${row['satuan']})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => line.sku = value),
              validator: (value) =>
                  value == null ? 'Barang wajib dipilih' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: line.qty,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Qty',
                helperText: selected == null
                    ? null
                    : 'Tersedia: ${selected['stok']} ${selected['satuan']}',
              ),
              validator: (value) {
                final qty = int.tryParse(value ?? '');
                if (qty == null || qty < 1) return 'Qty minimal 1';
                if (selected != null &&
                    qty > (selected['stok'] as num).toInt()) {
                  return 'Qty melebihi stok tersedia';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Wajib diisi' : null;
}

class _OutboundLine {
  String? sku;
  final qty = TextEditingController(text: '1');
  void dispose() => qty.dispose();
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.dangerBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(message, style: const TextStyle(color: AppColors.danger)),
  );
}
