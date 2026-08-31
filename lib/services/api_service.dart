import 'dart:convert';
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

  /// Membuat header HTTP standar (JSON + Bearer token jika ada).
  Future<Map<String, String>> _buildHeaders({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept':       'application/json',
    };
    if (withAuth) {
      final token = await _getToken();
      if (token != null) {
        // "Bearer" token dikirim di setiap request ke endpoint protected
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

    // jsonDecode() = ubah teks JSON dari server menjadi Map Dart
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Logout: hapus token di server.
  Future<void> logout() async {
    final url = Uri.parse('${AppConstants.apiUrl}/logout');
    final headers = await _buildHeaders();
    await http.post(url, headers: headers);
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  /// Ambil semua data dashboard (stat cards, chart, picking queue).
  Future<Map<String, dynamic>> getDashboard() async {
    return await _get('/dashboard');
  }

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

  /// Ambil daftar kategori untuk dropdown filter.
  Future<Map<String, dynamic>> getKategori() async {
    return await _get('/barang/kategori');
  }

  // ============================================================
  // INBOUND
  // ============================================================

  Future<Map<String, dynamic>> getInbound({int page = 1}) async {
    return await _get('/inbound', queryParams: {'page': '$page'});
  }

  Future<Map<String, dynamic>> getInboundDetail(int id) async {
    return await _get('/inbound/$id');
  }

  Future<Map<String, dynamic>> createInbound(Map<String, dynamic> data) async {
    return await _post('/inbound', data);
  }

  // ============================================================
  // OUTBOUND
  // ============================================================

  Future<Map<String, dynamic>> getOutbound({
    String? status,
    int page = 1,
  }) async {
    final params = <String, String>{'page': '$page'};
    if (status != null) params['status'] = status;
    return await _get('/outbound', queryParams: params);
  }

  Future<Map<String, dynamic>> getOutboundDetail(int id) async {
    return await _get('/outbound/$id');
  }

  Future<Map<String, dynamic>> createOutbound(Map<String, dynamic> data) async {
    return await _post('/outbound', data);
  }

  Future<Map<String, dynamic>> completePicking(int id) async {
    return await _post('/outbound/$id/picking-complete', {});
  }

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

  Future<Map<String, dynamic>> createStockOpname(Map<String, dynamic> data) async {
    return await _post('/stock-opname', data);
  }

  Future<Map<String, dynamic>> deleteStockOpname(int id) async {
    return await _delete('/stock-opname/$id');
  }

  // ============================================================
  // MASTER DATA (Supplier, Customer, Rack)
  // ============================================================

  Future<Map<String, dynamic>> getSuppliers({String? search}) async {
    final params = <String, String>{'per_page': '100'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    return await _get('/suppliers', queryParams: params);
  }

  Future<Map<String, dynamic>> getCustomers({String? search}) async {
    final params = <String, String>{'per_page': '100'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    return await _get('/customers', queryParams: params);
  }

  Future<Map<String, dynamic>> getRackLocations() async {
    return await _get('/rack-locations');
  }

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

  /// Proses response: jika OK parse JSON, jika error lempar exception.
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else if (response.statusCode == 401) {
      throw Exception('Sesi habis. Silakan login ulang.');
    } else if (response.statusCode == 422) {
      // Validation error dari Laravel
      final errors = body['errors'] as Map<String, dynamic>?;
      final firstError = errors?.values.first;
      final msg = firstError is List ? firstError.first : (body['message'] ?? 'Validasi gagal.');
      throw Exception(msg);
    } else {
      throw Exception(body['message'] ?? 'Terjadi kesalahan server.');
    }
  }
}
