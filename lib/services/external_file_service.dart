import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens server-generated documents consistently on desktop, native mobile,
/// and Flutter Web. Safari blocks delayed popups, so web reuses the current tab.
Future<void> openExternalDocument(String rawUrl, String documentName) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || !uri.hasScheme) {
    throw Exception('Tautan $documentName dari server tidak valid.');
  }

  final opened = await launchUrl(
    uri,
    mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    webOnlyWindowName: kIsWeb ? '_self' : null,
  );
  if (!opened) {
    throw Exception(
      '$documentName tidak dapat dibuka. Pastikan browser atau aplikasi pembaca dokumen tersedia.',
    );
  }
}
