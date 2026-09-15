import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});
  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiService().getActivityLogs();
      if (mounted) {
        setState(() {
          _items = r['data'] ?? [];
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: context.pagePadding,
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final row = _items[i];
          final raw = DateTime.tryParse(row['created_at'] ?? '');
          return WmsCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.surfaceLow,
                  child: Icon(Icons.history, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row['action'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        row['operator'] ?? '-',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (raw != null)
                  Text(
                    DateFormat('dd MMM HH:mm', 'id_ID').format(raw.toLocal()),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
