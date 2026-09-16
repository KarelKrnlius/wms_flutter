import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

/// api_service.dart
///
/// Ini adalah "jembatan" antara Flutter dan Laravel.
/// Semua komunikasi HTTP ke API server dipusatkan di sini.
///
/// CARA KERJA:
/// 1. Flutter memanggil fungsi di ApiService (misal: login(), getBarang())
/// 2. ApiService mengirim HTTP request ke Laravel API (JSON)
/// 3. Laravel memproses, mengambil data dari PostgreSQL, lalu balas JSON
/// 4. ApiService parse JSON → Flutter tampilkan ke layar

class ApiService {
  // Singleton: satu instance dipakai di seluruh aplikasi
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ============================================================
  // PRIVATE HELPER: Ambil token dari penyimpanan lokal HP
  // ============================================================

  /// Mengambil token Sanctum yang sudah disimpan saat login.
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  /// Membuat header HTTP standar (JSON + Bearer token + Ngrok bypass).
  Future<Map<String, String>> _buildHeaders({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Header wajib agar Ngrok tidak menampilkan halaman konfirmasi browser
      // saat request datang dari Flutter Web (Chrome) maupun mobile.
      'ngrok-skip-browser-warning': 'true',
    };
    if (withAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ============================================================
  // AUTENTIKASI
  // ============================================================

  /// Login: kirim username+password, terima token kembali.
  ///
  /// Contoh request: POST /api/login
  /// Body: { "login": "admin", "password": "password" }
  Future<Map<String, dynamic>> login(String loginInput, String password) async {
    final url = Uri.parse('${AppConstants.apiUrl}/login');
    final headers = await _buildHeaders(withAuth: false);

    // http.post() = kirim data ke server (seperti menekan tombol Submit di web)
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'login': loginInput, 'password': password}),
    );

    return _handleResponse(response);
  }

  /// Logout: hapus token di server.
  Future<void> logout() async {
    final url = Uri.parse('${AppConstants.apiUrl}/logout');
    final headers = await _buildHeaders();
    await http.post(url, headers: headers);
  }

  Future<Map<String, dynamic>> getSession() => _get('/me');

  Future<Map<String, dynamic>> saveStudentIdentity({
    required String name,
    required String studentClass,
    required String nis,
  }) => _post('/student-identity', {
    'name': name,
    'class': studentClass,
    'nis': nis,
  });

  Future<Map<String, dynamic>> resetStudentIdentity() =>
      _delete('/student-identity');

  // ============================================================
  // DASHBOARD
  // ============================================================

  /// Ambil semua data dashboard (stat cards, chart, picking queue).
  Future<Map<String, dynamic>> getDashboard({
    String periodTrx = 'hari_ini',
    String period = 'seminggu_ini',
  }) async {
    return await _get(
      '/dashboard',
      queryParams: {'period_trx': periodTrx, 'period': period},
    );
  }

  Future<Map<String, dynamic>> getReportLinks() => _get('/report-links');

  // ============================================================
  // MASTER DATA BARANG
  // ============================================================

  /// Ambil daftar barang. Bisa filter dengan search dan kategori.
  Future<Map<String, dynamic>> getBarang({
    String? search,
    String? kategori,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (kategori != null && kategori.isNotEmpty) params['kategori'] = kategori;
    return await _get('/barang', queryParams: params);
  }

  /// Ambil detail satu barang berdasarkan SKU.
  Future<Map<String, dynamic>> getBarangDetail(String sku) async {
    return await _get('/barang/${Uri.encodeComponent(sku)}');
  }

  Future<Map<String, dynamic>> getItemLabelLink(String sku) =>
      _get('/barang/${Uri.encodeComponent(sku)}/label-link');

  /// Ambil daftar kategori untuk dropdown filter.
  Future<Map<String, dynamic>> getKategori() async {
    return await _get('/barang/kategori');
  }

  // ============================================================
  // INBOUND
  // ============================================================

  Future<Map<String, dynamic>> getInbound({
    int page = 1,
    String? search,
  }) async {
    final params = <String, String>{'page': '$page'};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    return await _get('/inbound', queryParams: params);
  }

  Future<Map<String, dynamic>> getInboundDetail(String id) async {
    return await _get('/inbound/$id');
  }

  Future<Map<String, dynamic>> createInbound(Map<String, dynamic> data) async {
    return await _post('/inbound', data);
  }

  Future<Map<String, dynamic>> getInboundFormOptions() =>
      _get('/inbound-form-options');

  // ============================================================
  // OUTBOUND
  // ============================================================

  Future<Map<String, dynamic>> getOutbound({
    String? status,
    String? search,
    int page = 1,
  }) async {
    final params = <String, String>{'page': '$page'};
    if (status != null) params['status'] = status;
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    return await _get('/outbound', queryParams: params);
  }

  Future<Map<String, dynamic>> getOutboundDetail(String id) async {
    return await _get('/outbound/$id');
  }

  Future<Map<String, dynamic>> getOutboundDocumentLink(String id) =>
      _get('/outbound/$id/document-link');

  Future<Map<String, dynamic>> createOutbound(Map<String, dynamic> data) async {
    return await _post('/outbound', data);
  }

  Future<Map<String, dynamic>> getOutboundFormOptions() =>
      _get('/outbound-form-options');

  Future<Map<String, dynamic>> completePicking(
    String id,
    List<String> confirmedDetailIds,
  ) async {
    return await _post('/outbound/$id/picking-complete', {
      'confirmed_detail_ids': confirmedDetailIds,
    });
  }

  Future<Map<String, dynamic>> cancelInbound(String id, String reason) =>
      _post('/inbound/$id/cancel', {'reason': reason});
  Future<Map<String, dynamic>> cancelOutbound(String id, String reason) =>
      _post('/outbound/$id/cancel', {'reason': reason});
  Future<Map<String, dynamic>> getActivityLogs({int page = 1}) =>
      _get('/activity-logs', queryParams: {'page': '$page'});
  Future<Map<String, dynamic>> getPracticeSessions() =>
      _get('/practice-sessions');
  Future<Map<String, dynamic>> createPracticeSession(
    Map<String, dynamic> data,
  ) => _post('/practice-sessions', data);
  Future<Map<String, dynamic>> closePracticeSession(String id) =>
      _post('/practice-sessions/$id/close', {});

  // ============================================================
  // INVENTORY / KARTU STOK
  // ============================================================

  Future<Map<String, dynamic>> getKartuStok() async {
    return await _get('/inventory/kartu-stok');
  }

  Future<Map<String, dynamic>> getKartuStokDetail(String sku) async {
    return await _get('/inventory/kartu-stok/${Uri.encodeComponent(sku)}');
  }

  // ============================================================
  // STOCK OPNAME
  // ============================================================

  Future<Map<String, dynamic>> getStockOpname({int page = 1}) async {
    return await _get('/stock-opname', queryParams: {'page': '$page'});
  }

  Future<Map<String, dynamic>> createStockOpname(
    Map<String, dynamic> data,
  ) async {
    return await _post('/stock-opname', data);
  }

  // ============================================================
  // MASTER DATA (Supplier, Customer, Rack)
  // ============================================================

  Future<Map<String, dynamic>> getSuppliers({String? search}) async {
    final params = <String, String>{'per_page': '100'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    return await _get('/suppliers', queryParams: params);
  }

  Future<Map<String, dynamic>> createSupplier(Map<String, dynamic> data) =>
      _post('/suppliers', data);
  Future<Map<String, dynamic>> updateSupplier(
    String id,
    Map<String, dynamic> data,
  ) => _put('/suppliers/$id', data);

  Future<Map<String, dynamic>> getCustomers({String? search}) async {
    final params = <String, String>{'per_page': '100'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    return await _get('/customers', queryParams: params);
  }

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data) =>
      _post('/customers', data);
  Future<Map<String, dynamic>> updateCustomer(
    String id,
    Map<String, dynamic> data,
  ) => _put('/customers/$id', data);

  Future<Map<String, dynamic>> createUnit(String name) =>
      _post('/units', {'Nama': name});

  Future<Map<String, dynamic>> getRackLocations({String? search}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    return await _get(
      '/rack-locations',
      queryParams: params.isNotEmpty ? params : null,
    );
  }

  Future<Map<String, dynamic>> getRackDetail(String id) =>
      _get('/rack-locations/$id');

  /// Mengambil isi foto melalui API agar tetap berfungsi pada APK, Windows,
  /// dan Flutter Web meskipun backend diakses melalui ngrok.
  Future<Uint8List> getRackPhotoBytes(String id) async {
    final url = Uri.parse('${AppConstants.apiUrl}/rack-locations/$id/photo');
    final headers = await _buildHeaders();
    headers.remove('Content-Type');
    headers['Accept'] = 'image/*';
    final response = await http.get(url, headers: headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    if (response.statusCode == 404) {
      throw Exception('Foto rak tidak ditemukan atau sudah dihapus.');
    }
    if (response.statusCode == 401) {
      throw Exception('Sesi habis. Silakan login ulang.');
    }
    throw Exception(
      'Foto rak gagal dimuat (${response.statusCode}). Tarik layar ke bawah untuk mencoba lagi.',
    );
  }

  Future<Map<String, dynamic>> moveRackItem(
    String id,
    Map<String, dynamic> data,
  ) => _post('/rack-locations/$id/move-item', data);

  Future<Map<String, dynamic>> createRack(Map<String, dynamic> data) =>
      _post('/rack-locations', data);
  Future<Map<String, dynamic>> updateRack(
    String id,
    Map<String, dynamic> data,
  ) => _put('/rack-locations/$id', data);
  Future<Map<String, dynamic>> deleteRack(String id) =>
      _delete('/rack-locations/$id');

  Future<Map<String, dynamic>> uploadRackPhoto(
    String id,
    String? filePath,
    List<int>? bytes,
    String fileName,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.apiUrl}/rack-locations/$id/photo'),
    );
    final headers = await _buildHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    if (bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('foto', bytes, filename: fileName),
      );
    } else if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath('foto', filePath));
    } else {
      throw Exception('File foto tidak dapat dibaca dari perangkat ini.');
    }
    final streamed = await request.send();
    return _handleResponse(await http.Response.fromStream(streamed));
  }

  Future<Map<String, dynamic>> deleteRackPhoto(String id) =>
      _delete('/rack-locations/$id/photo');

  // ============================================================
  // PRIVATE BASE METHODS (GET, POST, DELETE)
  // ============================================================

  /// HTTP GET — ambil data dari server tanpa mengubah apa-apa.
  Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    var url = Uri.parse('${AppConstants.apiUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }
    final headers = await _buildHeaders();
    final response = await http.get(url, headers: headers);
    return _handleResponse(response);
  }

  /// HTTP POST — kirim data baru ke server (create).
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${AppConstants.apiUrl}$endpoint');
    final headers = await _buildHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// HTTP DELETE — hapus data di server.
  Future<Map<String, dynamic>> _delete(String endpoint) async {
    final url = Uri.parse('${AppConstants.apiUrl}$endpoint');
    final headers = await _buildHeaders();
    final response = await http.delete(url, headers: headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${AppConstants.apiUrl}$endpoint');
    final headers = await _buildHeaders();
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// Proses response: jika OK parse JSON, jika error lempar exception.
  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } on FormatException {
      throw Exception(
        'Server tidak mengembalikan JSON yang valid (${response.statusCode}). '
        'Periksa URL API dan pastikan backend Laravel aktif.',
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else if (response.statusCode == 401) {
      throw Exception('Sesi habis. Silakan login ulang.');
    } else if (response.statusCode == 422) {
      // Validation error dari Laravel
      final errors = body['errors'] as Map<String, dynamic>?;
      final firstError = errors?.values.first;
      final rawMessage = firstError is List
          ? firstError.first
          : (body['message'] ?? 'Validasi gagal.');
      throw Exception(_friendlyValidationMessage(rawMessage.toString()));
    } else if (response.statusCode == 403) {
      throw Exception(
        body['message'] ??
            'Akun ini tidak memiliki izin untuk tindakan tersebut.',
      );
    } else if (response.statusCode == 404) {
      throw Exception(
        body['message'] ??
            'Data yang diminta tidak ditemukan atau sudah dihapus.',
      );
    } else if (response.statusCode == 429) {
      throw Exception(
        'Terlalu banyak percobaan. Tunggu sekitar satu menit lalu coba kembali.',
      );
    } else if (response.statusCode >= 500) {
      // Jangan tampilkan SQL, stack trace, path server, atau detail internal
      // Laravel kepada pengguna aplikasi.
      throw Exception(
        'Layanan WMS sedang tidak tersedia. Pastikan Laravel dan PostgreSQL '
        'aktif, lalu coba lagi.',
      );
    } else {
      throw Exception(body['message'] ?? 'Terjadi kesalahan server.');
    }
  }

  String _friendlyValidationMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('reason') &&
        (lower.contains('10') || lower.contains('at least'))) {
      return 'Alasan pembatalan minimal 10 karakter agar dapat diproses.';
    }
    if (lower.contains('foto') &&
        (lower.contains('image') || lower.contains('mimes'))) {
      return 'Format foto tidak didukung. Gunakan JPG, JPEG, PNG, atau WebP.';
    }
    if (lower.contains('foto') &&
        (lower.contains('2048') || lower.contains('kilobytes'))) {
      return 'Ukuran foto maksimal 2 MB. Kompres atau pilih foto lain.';
    }
    if (lower.contains('required')) {
      return 'Masih ada data wajib yang belum diisi. Periksa kembali kolom yang ditandai.';
    }
    return message;
  }
}
