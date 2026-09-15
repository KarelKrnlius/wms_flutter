import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'core/responsive.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/activity_log_screen.dart';
import 'screens/admin/practice_session_screen.dart';
import 'screens/auth/student_identity_dialog.dart';
import 'screens/barang/barang_screen.dart';
import 'screens/customer/customer_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/inbound/inbound_screen.dart';
import 'screens/inventory/inventory_screen.dart';
import 'screens/outbound/outbound_screen.dart';
import 'screens/rack/rack_location_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/stock_opname/stock_opname_screen.dart';
import 'screens/supplier/supplier_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  int _mobileRefreshVersion = 0;
  Map<String, dynamic>? _user;
  bool _loadingUser = true;

  bool get _isAdmin => _user?['role'] == 'admin';

  List<_Destination> get _destinations => [
    const _Destination(
      'Dashboard',
      'Ringkasan operasional gudang',
      Icons.dashboard_outlined,
      Icons.dashboard,
      DashboardScreen(),
    ),
    const _Destination(
      'Data Barang',
      'SKU, stok, satuan, dan harga dasar',
      Icons.inventory_2_outlined,
      Icons.inventory_2,
      BarangScreen(),
      group: 'Master Data',
    ),
    const _Destination(
      'Lokasi Rak',
      'Kapasitas dan distribusi penyimpanan',
      Icons.shelves,
      Icons.shelves,
      RackLocationScreen(),
      group: 'Master Data',
    ),
    const _Destination(
      'Supplier',
      'Direktori pemasok',
      Icons.business_outlined,
      Icons.business,
      SupplierScreen(),
      group: 'Master Data',
    ),
    const _Destination(
      'Customer',
      'Direktori pelanggan',
      Icons.people_outline,
      Icons.people,
      CustomerScreen(),
      group: 'Master Data',
    ),
    const _Destination(
      'Inbound',
      'Penerimaan barang masuk',
      Icons.move_to_inbox_outlined,
      Icons.move_to_inbox,
      InboundScreen(),
      group: 'Operasional',
    ),
    const _Destination(
      'Outbound',
      'Pengiriman dan picking barang',
      Icons.outbox_outlined,
      Icons.outbox,
      OutboundScreen(),
      group: 'Operasional',
    ),
    if (_isAdmin)
      const _Destination(
        'Kartu Stok',
        'Mutasi dan saldo per SKU',
        Icons.receipt_long_outlined,
        Icons.receipt_long,
        InventoryScreen(),
        group: 'Inventori',
      ),
    const _Destination(
      'Stock Opname',
      'Catatan pemeriksaan kondisi fisik',
      Icons.fact_check_outlined,
      Icons.fact_check,
      StockOpnameScreen(),
      group: 'Inventori',
    ),
    const _Destination(
      'Laporan',
      'Export data gudang ke Excel',
      Icons.bar_chart_outlined,
      Icons.bar_chart,
      ReportsScreen(),
      group: 'Laporan',
    ),
    if (_isAdmin)
      const _Destination(
        'Sesi Praktikum',
        'Buka dan tutup periode latihan',
        Icons.school_outlined,
        Icons.school,
        PracticeSessionScreen(),
        group: 'Administrasi',
      ),
    if (_isAdmin)
      const _Destination(
        'Activity Log',
        'Jejak audit seluruh aktivitas',
        Icons.history_outlined,
        Icons.history,
        ActivityLogScreen(),
        group: 'Administrasi',
      ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _loadingUser = false;
      if (_selectedIndex >= _destinations.length) _selectedIndex = 0;
    });
    try {
      final response = await ApiService().getSession();
      final data = response['data'] as Map<String, dynamic>?;
      if (data?['requires_student_identity'] == true && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showStudentIdentityDialog(context);
        });
      }
    } catch (_) {
      // Layar tetap dapat menampilkan error per modul ketika backend offline.
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari sistem?'),
        content: const Text('Sesi pada perangkat ini akan diakhiri.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService().logout();
    } catch (_) {
      // Logout lokal tetap berjalan bila server sedang tidak terjangkau.
    }
    await AuthService().clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _resetStudentIdentity() async {
    try {
      await ApiService().resetStudentIdentity();
      if (!mounted) return;
      await showStudentIdentityDialog(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return switch (context.formFactor) {
      AppFormFactor.mobile => _buildMobile(),
      AppFormFactor.tablet => _buildTablet(),
      AppFormFactor.desktop => _buildDesktop(),
    };
  }

  Widget _buildMobile() {
    final items = [
      _destinations[0],
      _destinations.firstWhere((item) => item.label == 'Data Barang'),
      _destinations.firstWhere((item) => item.label == 'Inbound'),
      _destinations.firstWhere((item) => item.label == 'Outbound'),
    ];
    final current = _selectedIndex > 3 ? 4 : _selectedIndex;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const _Brand(),
        actions: [
          Chip(
            label: Text(_isAdmin ? 'Admin' : 'Siswa'),
            visualDensity: VisualDensity.compact,
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu akun',
            onSelected: (value) {
              if (value == 'identity') _resetStudentIdentity();
              if (value == 'logout') _logout();
            },
            itemBuilder: (_) => [
              if (!_isAdmin)
                const PopupMenuItem(
                  value: 'identity',
                  child: Text('Ganti identitas siswa'),
                ),
              const PopupMenuItem(value: 'logout', child: Text('Keluar')),
            ],
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: current == 4
          ? _MoreMenu(
              destinations: _destinations
                  .skip(1)
                  .where(
                    (item) => !const {
                      'Data Barang',
                      'Inbound',
                      'Outbound',
                    }.contains(item.label),
                  )
                  .toList(),
              isAdmin: _isAdmin,
            )
          : KeyedSubtree(
              key: ValueKey(
                'mobile-${items[current].label}-$current-$_mobileRefreshVersion',
              ),
              child: items[current].screen,
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        height: 68,
        onDestinationSelected: (index) => setState(() {
          _selectedIndex = index;
          _mobileRefreshVersion++;
        }),
        destinations: [
          ...items.map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: item.shortLabel,
            ),
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Lainnya',
          ),
        ],
      ),
    );
  }

  Widget _buildTablet() {
    final items = _destinations;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: _Brand(compact: true),
            ),
            destinations: items
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.activeIcon),
                    label: Text(item.shortLabel),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _workspace(items[_selectedIndex])),
        ],
      ),
    );
  }

  Widget _buildDesktop() {
    final items = _destinations;
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 264,
            child: _DesktopSidebar(
              destinations: items,
              selectedIndex: _selectedIndex,
              user: _user,
              onSelect: (index) => setState(() => _selectedIndex = index),
              onLogout: _logout,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _workspace(items[_selectedIndex])),
        ],
      ),
    );
  }

  Widget _workspace(_Destination item) => Column(
    children: [
      Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              avatar: Icon(
                _isAdmin ? Icons.admin_panel_settings : Icons.school,
                size: 16,
              ),
              label: Text(_isAdmin ? 'Guru / Admin' : 'Operator / Siswa'),
            ),
            PopupMenuButton<String>(
              tooltip: 'Menu akun',
              onSelected: (value) {
                if (value == 'identity') _resetStudentIdentity();
                if (value == 'logout') _logout();
              },
              itemBuilder: (_) => [
                if (!_isAdmin)
                  const PopupMenuItem(
                    value: 'identity',
                    child: Text('Ganti identitas siswa'),
                  ),
                const PopupMenuItem(value: 'logout', child: Text('Keluar')),
              ],
            ),
          ],
        ),
      ),
      Expanded(child: AdaptiveContent(child: item.screen)),
    ],
  );
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.destinations,
    required this.selectedIndex,
    required this.user,
    required this.onSelect,
    required this.onLogout,
  });
  final List<_Destination> destinations;
  final int selectedIndex;
  final Map<String, dynamic>? user;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    String? lastGroup;
    final entries = <Widget>[];
    for (var i = 0; i < destinations.length; i++) {
      final item = destinations[i];
      if (item.group != lastGroup) {
        lastGroup = item.group;
        entries.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 7),
            child: Text(
              (item.group ?? 'Utama').toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppColors.textHint,
              ),
            ),
          ),
        );
      }
      entries.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: ListTile(
            dense: true,
            selected: selectedIndex == i,
            selectedTileColor: const Color(0xFFEAF3FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            leading: Icon(
              selectedIndex == i ? item.activeIcon : item.icon,
              size: 20,
            ),
            title: Text(
              item.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onTap: () => onSelect(i),
          ),
        ),
      );
    }
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 20, 18, 14),
              child: _Brand(),
            ),
            const Divider(),
            Expanded(
              child: ListView(padding: EdgeInsets.zero, children: entries),
            ),
            const Divider(),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor: AppColors.dark,
                foregroundColor: Colors.white,
                child: Text(
                  '${user?['name'] ?? 'U'}'.substring(0, 1).toUpperCase(),
                ),
              ),
              title: Text(
                user?['name'] ?? 'Pengguna',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                user?['role_label'] ??
                    (user?['role'] == 'admin'
                        ? 'Guru (Admin)'
                        : 'Operator (Siswa)'),
              ),
              trailing: IconButton(
                onPressed: onLogout,
                tooltip: 'Keluar',
                icon: const Icon(Icons.logout, size: 19),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.destinations, required this.isAdmin});
  final List<_Destination> destinations;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: context.pagePadding,
      children: [
        const Text(
          'Menu WMS',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          isAdmin ? 'Akses Guru / Admin' : 'Akses Operator / Siswa',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.12,
          ),
          itemCount: destinations.length,
          itemBuilder: (context, index) {
            final item = destinations[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(item.label)),
                      body: item.screen,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, color: AppColors.primary),
                      const Spacer(),
                      Text(
                        item.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.warehouse, color: Colors.white, size: 20),
    );
    if (compact) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 11),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WMS Prototipe 2',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            Text(
              'Warehouse Management System',
              style: TextStyle(fontSize: 9, color: AppColors.textHint),
            ),
          ],
        ),
      ],
    );
  }
}

class _Destination {
  const _Destination(
    this.label,
    this.subtitle,
    this.icon,
    this.activeIcon,
    this.screen, {
    this.group,
  });
  final String label;
  final String subtitle;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
  final String? group;

  String get shortLabel => switch (label) {
    'Data Barang' => 'Barang',
    'Lokasi Rak' => 'Rak',
    'Stock Opname' => 'Opname',
    'Kartu Stok' => 'Stok',
    _ => label,
  };
}
