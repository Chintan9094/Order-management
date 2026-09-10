import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/realtime/realtime_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/order_status_machine.dart';
import '../../../shared/domain/enums.dart';
import '../../../shared/domain/staff_permissions.dart';
import '../providers/staff_providers.dart';
import 'staff_place_order_screen.dart';

class StaffOrdersTab extends ConsumerStatefulWidget {
  const StaffOrdersTab({super.key});

  @override
  ConsumerState<StaffOrdersTab> createState() => _StaffOrdersTabState();
}

class _StaffOrdersTabState extends ConsumerState<StaffOrdersTab> {
  StreamSubscription? _sub;
  OrderStatus? _filter;
  String? _busyOrderId;

  static const _filterStatuses = <OrderStatus>[
    OrderStatus.pending,
    OrderStatus.accepted,
    OrderStatus.preparing,
    OrderStatus.served,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurantId =
          ref.read(authControllerProvider).user?.restaurantId;
      if (restaurantId == null) return;
      _sub = ref
          .read(orderEventSourceProvider)
          .watchRestaurantOrders(restaurantId)
          .listen((_) => ref.invalidate(staffOrdersProvider));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _updateStatus(Order order, OrderStatus next) async {
    setState(() => _busyOrderId = order.id);
    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(
            orderId: order.id,
            status: next,
          );
      ref.invalidate(staffOrdersProvider);
      ref.invalidate(staffDashboardProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  Future<void> _openPlaceOrder() async {
    final placed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const StaffPlaceOrderScreen(),
      ),
    );
    if (placed == true) {
      ref.invalidate(staffOrdersProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(staffOrdersProvider);
    final user = ref.watch(authControllerProvider).user;
    final role = user?.role;
    final isManager = role == StaffRole.admin || role == StaffRole.manager;
    final canPlaceOrder = user?.hasPermission(StaffPermissions.manageOrders) ??
        false;

    return async.when(
      loading: () => const AppLoading(message: 'Loading orders…'),
      error: (e, _) => AppErrorView(
        error: e,
        onRetry: () => ref.invalidate(staffOrdersProvider),
      ),
      data: (orders) {
        final filtered = _filter == null
            ? orders
            : orders.where((o) => o.status == _filter).toList();

        return Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                      ),
                      ..._filterStatuses.map(
                        (s) => _FilterChip(
                          label: _label(s),
                          selected: _filter == s,
                          onTap: () => setState(() => _filter = s),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const AppEmptyState(
                          title: 'No orders',
                          subtitle: 'Incoming orders will appear here.',
                          icon: Icons.receipt_long_outlined,
                        )
                      : RefreshIndicator(
                          onRefresh: () async =>
                              ref.invalidate(staffOrdersProvider),
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.sm,
                              AppSpacing.md,
                              canPlaceOrder ? 88 : AppSpacing.md,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final order = filtered[index];
                              final next = _nextStatus(order.status);
                              final canCancel = OrderStatusMachine.canCancel(
                                current: order.status,
                                isManagerOrAbove: isManager,
                              );
                              final busy = _busyOrderId == order.id;

                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: AppSpacing.radiusMd,
                                  border: Border.all(color: AppColors.outline),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x080F1419),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Order #${order.id} · Table ${order.tableId}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ),
                                        StatusBadge(
                                          label: _label(order.status),
                                          color: _statusColor(order.status),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    ...order.items.map(
                                      (i) => Text(
                                        '${i.quantity}× ${i.nameSnapshot}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      CurrencyFormatter.format(order.grandTotal),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    if (next != null || canCancel) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      Wrap(
                                        spacing: AppSpacing.xs,
                                        children: [
                                          if (next != null)
                                            FilledButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => _updateStatus(
                                                        order,
                                                        next,
                                                      ),
                                              style: FilledButton.styleFrom(
                                                minimumSize: const Size(0, 40),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                ),
                                                backgroundColor:
                                                    AppColors.saffron,
                                              ),
                                              child: Text(_actionLabel(next)),
                                            ),
                                          if (canCancel)
                                            OutlinedButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => _updateStatus(
                                                        order,
                                                        OrderStatus.cancelled,
                                                      ),
                                              style: OutlinedButton.styleFrom(
                                                minimumSize: const Size(0, 40),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                ),
                                              ),
                                              child: const Text('Cancel'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
            if (canPlaceOrder)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  heroTag: 'staff-place-order',
                  backgroundColor: AppColors.saffron,
                  onPressed: _openPlaceOrder,
                  icon: const Icon(Icons.add),
                  label: const Text('Order for table'),
                ),
              ),
          ],
        );
      },
    );
  }

  OrderStatus? _nextStatus(OrderStatus current) {
    return switch (current) {
      OrderStatus.pending => OrderStatus.accepted,
      OrderStatus.accepted => OrderStatus.preparing,
      OrderStatus.preparing || OrderStatus.ready => OrderStatus.served,
      OrderStatus.served => OrderStatus.completed,
      _ => null,
    };
  }

  String _actionLabel(OrderStatus next) {
    return switch (next) {
      OrderStatus.accepted => 'Accept',
      OrderStatus.preparing => 'Prepare',
      OrderStatus.served => 'Serve',
      OrderStatus.completed => 'Completed',
      _ => 'Update',
    };
  }

  String _label(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => 'Pending',
      OrderStatus.accepted => 'Accepted',
      OrderStatus.preparing => 'Preparing',
      OrderStatus.ready => 'Ready',
      OrderStatus.served => 'Served',
      OrderStatus.completed => 'Completed',
      OrderStatus.cancelled => 'Cancelled',
    };
  }

  Color _statusColor(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => AppColors.statusPending,
      OrderStatus.accepted || OrderStatus.preparing =>
        AppColors.statusPreparing,
      OrderStatus.ready || OrderStatus.served => AppColors.statusReady,
      OrderStatus.completed => AppColors.statusPaid,
      OrderStatus.cancelled => AppColors.statusCancelled,
    };
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.ink,
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : AppColors.ink,
            ),
      ),
    );
  }
}
