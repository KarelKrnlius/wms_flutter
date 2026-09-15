import 'package:flutter/material.dart';

import '../../services/api_service.dart';

Future<Map<String, dynamic>?> showQuickPartyDialog(
  BuildContext context, {
  required bool supplier,
  Map<String, dynamic>? initial,
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onSave,
}) async {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: initial?['nama']?.toString());
  final phone = TextEditingController(text: initial?['no_kontak']?.toString());
  final email = TextEditingController(text: initial?['email']?.toString());
  final address = TextEditingController(text: initial?['alamat']?.toString());
  var saving = false;
  String? error;
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(
          '${initial == null ? 'Tambah' : 'Edit'} ${supplier ? 'Supplier' : 'Customer'}',
        ),
        content: SizedBox(
          width: 460,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error != null) ...[
                    Text(error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: name,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Nama'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nama wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'No. kontak'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: address,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Alamat'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      final payload = {
                        'Nama': name.text.trim(),
                        'No_Kontak': phone.text.trim(),
                        'Email': email.text.trim(),
                        'Alamat': address.text.trim(),
                      };
                      final response = onSave != null
                          ? await onSave(payload)
                          : supplier
                          ? await ApiService().createSupplier(payload)
                          : await ApiService().createCustomer(payload);
                      if (dialogContext.mounted) {
                        Navigator.pop(
                          dialogContext,
                          (response['data'] as Map<String, dynamic>?) ??
                              {
                                ...?initial,
                                'nama': payload['Nama'],
                                'no_kontak': payload['No_Kontak'],
                                'email': payload['Email'],
                                'alamat': payload['Alamat'],
                              },
                        );
                      }
                    } catch (e) {
                      setDialogState(() {
                        saving = false;
                        error = e.toString().replaceFirst('Exception: ', '');
                      });
                    }
                  },
            child: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  phone.dispose();
  email.dispose();
  address.dispose();
  return result;
}
