import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/barang/barang_screen.dart';
import 'screens/inbound/inbound_screen.dart';
import 'screens/outbound/outbound_screen.dart';
import 'screens/inventory/inventory_screen.dart';
import 'screens/supplier/supplier_screen.dart';
import 'screens/customer/customer_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _user;

  final List<_NavItem> _navItems = [
    _NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined,    activeIcon: Icons.dashboard,          screen: const DashboardScreen()),
    _NavItem(label: 'Barang',    icon: Icons.inventory_2_outlined,   activeIcon: Icons.inventory_2,        screen: const BarangScreen()),
    _NavItem(label: 'Inbound',   icon: Icons.arrow_downward_rounded, activeIcon: Icons.arrow_downward_rounded, screen: const InboundScreen()),
    _NavItem(label: 'Outbound',  icon: Icons.arrow_upward_rounded,   activeIcon: Icons.arrow_upward_rounded,   screen: const OutboundScreen()),
    _NavItem(label: 'Lainnya',   icon: Icons.grid_view_outlined,     activeIcon: Icons.grid_view,          screen: const _MoreScreen()),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await AuthService().getUser();
    setState(() => _user = u);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Sistem'),
        content: const Text('Apakah kamu yakin ingin logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ApiService().logout();
    await AuthService().clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _user?['role'] == 'admin';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: AppColors.dark, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.warehouse, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Text('WMS Prototipe 2',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isAdmin ? AppColors.dark : const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(children: [
              Icon(isAdmin ? Icons.admin_panel_settings : Icons.school,
                  size: 11, color: isAdmin ? Colors.white : AppColors.primary),
              const SizedBox(width: 4),
              Text(isAdmin ? 'Admin' : 'Operator',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: isAdmin ? Colors.white : AppColors.primary)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 18, color: AppColors.danger),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _navItems.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          elevation: 0,
          items: _navItems.map((item) => BottomNavigationBarItem(
            icon: Icon(item.icon, size: 22),
            activeIcon: Icon(item.activeIcon, size: 22),
            label: item.label,
          )).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
  const _NavItem({required this.label, required this.icon, required this.activeIcon, required this.screen});
}

// ---- HALAMAN "LAINNYA" ----
class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _MenuItem(label: 'Kartu Stok', icon: Icons.receipt_long_outlined,  color: AppColors.primary,         route: const InventoryScreen()),
      _MenuItem(label: 'Supplier',   icon: Icons.business_outlined,        color: const Color(0xFF7C3AED),   route: const SupplierScreen()),
      _MenuItem(label: 'Customer',   icon: Icons.people_outline,           color: const Color(0xFF0891B2),   route: const CustomerScreen()),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          const Text('Menu Lainnya',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: menuItems.map((m) => InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => m.route)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: m.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(m.icon, color: m.color, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(m.label, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ]),
              ),
            )).toList(),
          ),
        ]),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final Widget route;
  const _MenuItem({required this.label, required this.icon, required this.color, required this.route});
}
