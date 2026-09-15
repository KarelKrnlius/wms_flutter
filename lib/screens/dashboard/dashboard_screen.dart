import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _transactionPeriod = 'hari_ini';
  String _chartPeriod = 'seminggu_ini';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService().getDashboard(
        periodTrx: _transactionPeriod,
        period: _chartPeriod,
      );
      setState(() {
        _data = result['data'];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _fmt(dynamic v) {
    if (v == null) return '0';
    final n = v is int ? v : int.tryParse(v.toString()) ?? 0;
    return NumberFormat('#,###', 'id_ID').format(n);
  }

  String _fmtRupiah(dynamic v) {
    if (v == null) return 'Rp 0';
    final n = v is num ? v : num.tryParse(v.toString()) ?? 0;
    if (n >= 1000000) return 'Rp ${(n / 1000000).toStringAsFixed(1)}Jt';
    if (n >= 1000) return 'Rp ${(n / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${NumberFormat('#,###', 'id_ID').format(n)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final stats = _data!['stats'] as Map<String, dynamic>;
    final lowStock = (_data!['low_stock_items'] as List?) ?? [];
    final pickingQ = (_data!['picking_queue'] as List?) ?? [];
    final chart = (_data!['chart'] as Map<String, dynamic>?) ?? {};
    const trxLabels = {
      'hari_ini': 'Hari Ini',
      '7_hari': '7 Hari',
      '1_bulan': 'Bulan Ini',
      '1_tahun': 'Tahun Ini',
      'semua': 'Semua',
    };

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: context.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!context.isDesktop) ...[
              const Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ringkasan kondisi gudang real-time',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              const SizedBox(height: 16),
            ],

            // ---- STAT CARDS ----
            GridView.count(
              crossAxisCount: context.isDesktop ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: context.isDesktop
                  ? 1.85
                  : (context.isMobile ? 1.35 : 1.6),
              children: [
                StatCard(
                  label: 'Total SKU',
                  value: _fmt(stats['total_sku']),
                  subtitle: 'Jenis barang',
                  icon: Icons.inventory_2_outlined,
                  iconBg: AppColors.surfaceLow,
                  iconColor: AppColors.textSecondary,
                ),
                StatCard(
                  label: 'Total Stok',
                  value: _fmt(stats['total_stok']),
                  subtitle: 'unit di gudang',
                  icon: Icons.category_outlined,
                  iconBg: AppColors.successBg,
                  iconColor: AppColors.success,
                  valueColor: AppColors.success,
                ),
                StatCard(
                  label: 'Nilai Gudang',
                  value: _fmtRupiah(stats['nilai_gudang']),
                  subtitle: 'Total aset',
                  icon: Icons.savings_outlined,
                  iconBg: Color(0xFFEEF2FF),
                  iconColor: Color(0xFF4F46E5),
                ),
                StatCard(
                  label: 'Stok Direservasi',
                  value: _fmt(stats['total_reserved']),
                  subtitle: 'Menunggu picking',
                  icon: Icons.lock_clock_outlined,
                  iconBg: AppColors.warningBg,
                  iconColor: AppColors.warning,
                  valueColor: AppColors.warning,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: context.isDesktop ? 220 : double.infinity,
                child: DropdownButtonFormField<String>(
                  initialValue: _transactionPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Skala transaksi',
                  ),
                  items: trxLabels.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _transactionPeriod = value;
                      _load();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (context.isMobile)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  StatCard(
                    label: 'Inbound',
                    value: _fmt(stats['inbound_today']),
                    subtitle:
                        '${trxLabels[_transactionPeriod]} • Transaksi masuk',
                    icon: Icons.arrow_downward_rounded,
                    iconBg: AppColors.successBg,
                    iconColor: AppColors.success,
                    valueColor: AppColors.success,
                  ),
                  StatCard(
                    label: 'Outbound',
                    value: _fmt(stats['outbound_today']),
                    subtitle:
                        '${trxLabels[_transactionPeriod]} • Transaksi keluar',
                    icon: Icons.arrow_upward_rounded,
                    iconBg: Color(0xFFDBEAFE),
                    iconColor: AppColors.primary,
                    valueColor: AppColors.primary,
                  ),
                  StatCard(
                    label: 'Pending Picking',
                    value: _fmt(stats['pending_picking']),
                    subtitle: 'Menunggu diproses',
                    icon: Icons.assignment_outlined,
                    iconBg: AppColors.warningBg,
                    iconColor: AppColors.warning,
                    valueColor: AppColors.warning,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Inbound ${trxLabels[_transactionPeriod]}',
                      value: _fmt(stats['inbound_today']),
                      subtitle: 'Transaksi masuk',
                      icon: Icons.arrow_downward_rounded,
                      iconBg: AppColors.successBg,
                      iconColor: AppColors.success,
                      valueColor: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Outbound ${trxLabels[_transactionPeriod]}',
                      value: _fmt(stats['outbound_today']),
                      subtitle: 'Transaksi keluar',
                      icon: Icons.arrow_upward_rounded,
                      iconBg: const Color(0xFFDBEAFE),
                      iconColor: AppColors.primary,
                      valueColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Pending Picking',
                      value: _fmt(stats['pending_picking']),
                      subtitle: 'Dokumen diproses',
                      icon: Icons.assignment_outlined,
                      iconBg: AppColors.warningBg,
                      iconColor: AppColors.warning,
                      valueColor: AppColors.warning,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            if (chart.isNotEmpty) ...[
              _WeeklyChart(
                data: chart,
                period: _chartPeriod,
                onPeriodChanged: (value) {
                  _chartPeriod = value;
                  _load();
                },
              ),
              const SizedBox(height: 16),
            ],

            // ---- PICKING QUEUE ----
            if (pickingQ.isNotEmpty) ...[
              WmsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pending_actions,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Antrian Picking',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: '${pickingQ.length} pending',
                            type: BadgeType.warning,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...pickingQ.map(
                      (trx) =>
                          _PickingQueueItem(trx: trx as Map<String, dynamic>),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ---- LOW STOCK ALERTS ----
            if (lowStock.isNotEmpty) ...[
              WmsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.dangerBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Critical Stock Alerts',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: '${lowStock.length} item',
                            type: BadgeType.danger,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...lowStock.map(
                      (item) =>
                          _LowStockItem(item: item as Map<String, dynamic>),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({
    required this.data,
    required this.period,
    required this.onPeriodChanged,
  });
  final Map<String, dynamic> data;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final labels = (data['labels'] as List?) ?? [];
    final inbound = (data['inbound'] as List?) ?? [];
    final outbound = (data['outbound'] as List?) ?? [];
    final values = [...inbound, ...outbound].map((e) => (e as num).toDouble());
    final maxValue = values.isEmpty
        ? 10.0
        : values.reduce((a, b) => a > b ? a : b).clamp(10, double.infinity) *
              1.2;
    return WmsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (context.isMobile) ...[
            const Text(
              'Aktivitas Inbound vs Outbound',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: DropdownButton<String>(
                value: period,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(
                    value: 'seminggu_ini',
                    child: Text('Minggu Ini'),
                  ),
                  DropdownMenuItem(value: 'seminggu', child: Text('7 Hari')),
                  DropdownMenuItem(value: 'sebulan', child: Text('Sebulan')),
                  DropdownMenuItem(value: 'setahun', child: Text('Setahun')),
                ],
                onChanged: (value) {
                  if (value != null) onPeriodChanged(value);
                },
              ),
            ),
          ] else
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Aktivitas Inbound vs Outbound',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                DropdownButton<String>(
                  value: period,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'seminggu_ini', child: Text('Minggu Ini')),
                    DropdownMenuItem(value: 'seminggu', child: Text('7 Hari')),
                    DropdownMenuItem(value: 'sebulan', child: Text('Sebulan')),
                    DropdownMenuItem(value: 'setahun', child: Text('Setahun')),
                  ],
                  onChanged: (value) {
                    if (value != null) onPeriodChanged(value);
                  },
                ),
              ],
            ),
          const SizedBox(height: 4),
          const Text(
            'Perbandingan kuantitas inbound dan outbound',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: context.isDesktop ? 260 : 210,
            child: BarChart(
              BarChartData(
                maxY: maxValue,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 34),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Text(
                            labels[index].toString(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  labels.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: (inbound[index] as num).toDouble(),
                        color: AppColors.success,
                        width: context.isDesktop ? 12 : 7,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      BarChartRodData(
                        toY: (outbound[index] as num).toDouble(),
                        color: AppColors.primary,
                        width: context.isDesktop ? 12 : 7,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _ChartLegend(color: AppColors.success, label: 'Inbound'),
              SizedBox(width: 16),
              _ChartLegend(color: AppColors.primary, label: 'Outbound'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    ],
  );
}

class _PickingQueueItem extends StatelessWidget {
  final Map<String, dynamic> trx;
  const _PickingQueueItem({required this.trx});

  @override
  Widget build(BuildContext context) {
    final priority = trx['priority'] ?? 'decent';
    BadgeType badgeType = priority == 'high'
        ? BadgeType.danger
        : (priority == 'normal' ? BadgeType.warning : BadgeType.success);

    Color iconBg = badgeType == BadgeType.danger
        ? AppColors.dangerBg
        : (badgeType == BadgeType.warning
              ? AppColors.warningBg
              : AppColors.successBg);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trx['no_shipping'] ?? '-',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  trx['customer_nama'] ?? '-',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: trx['priority_label'] ?? '-', type: badgeType),
        ],
      ),
    );
  }
}

class _LowStockItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const _LowStockItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item['status_stok'] ?? 'Aman';
    final isHabis = status == 'Habis';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama'] ?? '-',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  item['sku'] ?? '-',
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
              Text(
                'Stok: ${item['stok']}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isHabis ? AppColors.danger : AppColors.warning,
                ),
              ),
              StatusBadge(
                label: status,
                type: isHabis ? BadgeType.danger : BadgeType.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
