import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../shared/domain/enums.dart';
import '../providers/staff_providers.dart';

class StaffDashboardTab extends ConsumerWidget {
  const StaffDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffDashboardProvider);
    final textTheme = Theme.of(context).textTheme;

    return async.when(
      loading: () => const AppLoading(message: 'Loading dashboard…'),
      error: (e, _) => AppErrorView(
        error: e,
        onRetry: () => ref.invalidate(staffDashboardProvider),
      ),
      data: (data) {
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(staffDashboardProvider),
          child: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              Text('Floor overview', style: textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                'Live snapshot for Spice Garden',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _StatCard(
                    label: 'Open sessions',
                    value: '${data.stats.openSessions}',
                    accent: AppColors.info,
                    soft: AppColors.infoSoft,
                    icon: Icons.groups_rounded,
                  ),
                  _StatCard(
                    label: 'Active orders',
                    value: '${data.stats.activeOrders}',
                    accent: AppColors.saffronDark,
                    soft: AppColors.saffronSoft,
                    icon: Icons.receipt_long_rounded,
                  ),
                  _StatCard(
                    label: 'Payment pending',
                    value: '${data.stats.unpaidSessions}',
                    accent: AppColors.warning,
                    soft: AppColors.saffronSoft,
                    icon: Icons.payments_outlined,
                  ),
                  _StatCard(
                    label: 'Tables',
                    value: '${data.stats.tables}',
                    accent: AppColors.sage,
                    soft: AppColors.sageSoft,
                    icon: Icons.table_restaurant_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(
                title: 'Recent orders',
                subtitle: 'Latest activity across tables',
              ),
              const SizedBox(height: AppSpacing.sm),
              if (data.recentOrders.isEmpty)
                AppSurface(
                  child: Text('No orders yet.', style: textTheme.bodyMedium),
                )
              else
                ...data.recentOrders.map(_RecentOrderTile.new),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.soft,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final Color soft;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppSurface(
      color: soft,
      borderColor: accent.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const Spacer(),
          Text(value, style: textTheme.headlineMedium),
          const SizedBox(height: 2),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile(this.order);

  final Order order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppSurface(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.mistDeep,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant_rounded, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${order.id}', style: textTheme.titleMedium),
                  Text(
                    'Table ${order.tableId} · ${_label(order.status)}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(order.grandTotal),
              style: textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }

  String _label(OrderStatus status) =>
      status.name[0].toUpperCase() + status.name.substring(1);
}
