import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';

class RackDetailScreen extends StatefulWidget {
  const RackDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<RackDetailScreen> createState() => _RackDetailScreenState();
}

class _RackDetailScreenState extends State<RackDetailScreen> {
  Map<String, dynamic>? data;
  String? error;
  bool _isAdmin = false;
  bool _photoBusy = false;
  bool _photoLoading = false;
  Uint8List? _photoBytes;
  String? _photoError;

  @override
  void initState() {
    super.initState();
    _load();
    AuthService().isAdmin().then((value) {
      if (mounted) setState(() => _isAdmin = value);
    });
  }

  Future<void> _uploadPhoto() async {
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: kIsWeb,
    );
    if (selected == null) return;
    final file = selected.files.single;
    if (file.size > 2 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Foto terlalu besar. Pilih JPG, PNG, atau WebP maksimal 2 MB.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (file.path == null && file.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Foto tidak dapat dibaca. Pilih foto lain dari galeri atau aplikasi File.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() => _photoBusy = true);
    try {
      final response = await ApiService().uploadRackPhoto(
        widget.id,
        file.path,
        file.bytes,
        file.name,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message'])));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _deletePhoto() async {
    setState(() => _photoBusy = true);
    try {
      final response = await ApiService().deleteRackPhoto(widget.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message'])));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  void _showPhotoViewer() {
    final bytes = _photoBytes;
    if (bytes == null) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .92),
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF090D14),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: .8,
                maxScale: 5,
                child: Center(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Text(
                      'Foto rak tidak dapat dimuat',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton.filled(
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close),
              ),
            ),
            const Positioned(
              left: 20,
              bottom: 18,
              child: Text(
                'Cubit atau scroll untuk zoom • Geser untuk melihat detail',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoCard(BuildContext context) {
    final hasPhoto = data!['has_photo'] == true || data!['foto_url'] != null;
    return WmsCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: context.isMobile ? 4 / 3 : 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: const Color(0xFF111827),
                child: hasPhoto
                    ? InkWell(
                        onTap: _photoBytes == null ? null : _showPhotoViewer,
                        child: _photoLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _photoBytes != null
                            ? Image.memory(_photoBytes!, fit: BoxFit.contain)
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.broken_image_outlined,
                                        size: 44,
                                        color: Colors.white54,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _photoError ??
                                            'Foto rak tidak dapat dimuat.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                        onPressed: _load,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Coba lagi'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_outlined,
                              size: 52,
                              color: Colors.white38,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Belum ada foto rak',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
              ),
              if (_photoBytes != null)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: context.isMobile
                      ? IconButton.filledTonal(
                          tooltip: 'Lihat foto penuh',
                          onPressed: _showPhotoViewer,
                          icon: const Icon(Icons.fullscreen),
                        )
                      : FilledButton.tonalIcon(
                          onPressed: _showPhotoViewer,
                          icon: const Icon(Icons.fullscreen, size: 18),
                          label: const Text('Lihat penuh'),
                        ),
                ),
              if (_isAdmin)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Row(
                    children: [
                      if (hasPhoto)
                        IconButton.filledTonal(
                          tooltip: 'Hapus foto',
                          onPressed: _photoBusy ? null : _deletePhoto,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      const SizedBox(width: 8),
                      if (context.isMobile)
                        IconButton.filled(
                          tooltip: hasPhoto ? 'Ganti foto' : 'Upload foto',
                          onPressed: _photoBusy ? null : _uploadPhoto,
                          icon: _photoBusy
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_outlined),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _photoBusy ? null : _uploadPhoto,
                          icon: _photoBusy
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_outlined),
                          label: Text(hasPhoto ? 'Ganti' : 'Upload'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rackInfoCard() => WmsCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data!['kode_rak'],
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Lorong ${data!['aisle']} • Level ${data!['level']}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        const Text(
          'Kapasitas rak',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          value: data!['kapasitas'] > 0
              ? data!['kapasitas_terpakai'] / data!['kapasitas']
              : 0,
        ),
        const SizedBox(height: 8),
        Text(
          '${data!['kapasitas_terpakai']} / ${data!['kapasitas']} unit terpakai',
        ),
      ],
    ),
  );

  Widget _overview(BuildContext context) {
    if (!context.isDesktop) {
      return Column(
        children: [
          _photoCard(context),
          const SizedBox(height: 16),
          _rackInfoCard(),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final photoWidth = (constraints.maxWidth - gap) * 3 / 5;
        final cardHeight = photoWidth * 9 / 16;
        return SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: _photoCard(context)),
              const SizedBox(width: gap),
              Expanded(flex: 2, child: _rackInfoCard()),
            ],
          ),
        );
      },
    );
  }

  Future<void> _load() async {
    setState(() {
      error = null;
      _photoError = null;
    });
    try {
      final response = await ApiService().getRackDetail(widget.id);
      if (!mounted) return;
      final loaded = response['data'] as Map<String, dynamic>;
      final hasPhoto = loaded['has_photo'] == true || loaded['foto_url'] != null;
      setState(() {
        data = loaded;
        _photoBytes = null;
        _photoLoading = hasPhoto;
      });
      if (hasPhoto) {
        try {
          final bytes = await ApiService().getRackPhotoBytes(widget.id);
          if (mounted) setState(() => _photoBytes = bytes);
        } catch (e) {
          if (mounted) {
            setState(
              () => _photoError = e.toString().replaceFirst('Exception: ', ''),
            );
          }
        } finally {
          if (mounted) setState(() => _photoLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _move(Map<String, dynamic> item) async {
    final racks = (data?['other_racks'] as List?) ?? [];
    String? target;
    final qty = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Pindahkan ${item['nama']}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Tersedia: ${item['stok_tersedia']} ${item['satuan']}'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: target,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Rak tujuan'),
                  items: racks
                      .map<DropdownMenuItem<String>>(
                        (rack) => DropdownMenuItem(
                          value: rack['id'].toString(),
                          child: Text(
                            '${rack['kode_rak']} • sisa ${rack['sisa']}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => target = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qty,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Qty dipindahkan',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: target == null || (int.tryParse(qty.text) ?? 0) < 1
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Pindahkan'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && target != null) {
      try {
        final response = await ApiService().moveRackItem(widget.id, {
          'sku': item['sku'],
          'new_rack_id': target,
          'qty': int.parse(qty.text),
        });
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response['message'])));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
            ),
          );
        }
      }
    }
    qty.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(data?['kode_rak'] ?? 'Detail Rak'),
      actions: [
        IconButton(
          tooltip: 'Muat ulang data rak',
          onPressed: _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: error != null
        ? ErrorView(message: error!, onRetry: _load)
        : data == null
        ? const LoadingView()
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _overview(context),
                const SizedBox(height: 16),
                const Text(
                  'Barang di Rak',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...((data!['items'] as List).map((raw) {
                  final item = raw as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: WmsCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['nama'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${item['sku']} • tersedia ${item['stok_tersedia']} ${item['satuan']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: item['stok_tersedia'] > 0
                                ? () => _move(item)
                                : null,
                            tooltip: 'Pindahkan barang',
                            icon: const Icon(Icons.drive_file_move_outline),
                          ),
                        ],
                      ),
                    ),
                  );
                })),
              ],
            ),
          ),
  );
}
