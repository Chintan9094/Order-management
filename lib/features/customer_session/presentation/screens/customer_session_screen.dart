import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/realtime/order_event_source.dart';
import '../../../../core/realtime/realtime_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../routing/routes.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../shared/domain/enums.dart';
import '../providers/customer_session_providers.dart';
import '../providers/session_detail_provider.dart';

class CustomerSessionScreen extends ConsumerStatefulWidget {
  const CustomerSessionScreen({super.key});

  @override
  ConsumerState<CustomerSessionScreen> createState() =>
      _CustomerSessionScreenState();
}

class _CustomerSessionScreenState extends ConsumerState<CustomerSessionScreen> {
  StreamSubscription<SessionRealtimeEvent>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(activeCustomerSessionProvider);
      if (session == null) return;
      _sub = ref
          .read(orderEventSourceProvider)
          .watchSession(session.sessionId)
          .listen((_) {
        ref.invalidate(sessionDetailProvider);
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeCustomerSessionProvider);
    final detailAsync = ref.watch(sessionDetailProvider);
    final textTheme = Theme.of(context).textTheme;

    if (active == null) {
      return Scaffold(
        body: PageBackground(
          child: AppErrorView(
            error: 'No active session.',
            onRetry: () => context.go(AppRoutes.home),
          ),
        ),
      );
    }

    return Scaffold(
      body: PageBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go(AppRoutes.customerMenu),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        '${active.tableLabel} orders',
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.invalidate(sessionDetailProvider),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: detailAsync.when(
                  loading: () => const AppLoading(message: 'Loading orders…'),
                  error: (e, _) => AppErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(sessionDetailProvider),
                  ),
                  data: (detail) {
                    final orders = detail.orders;
                    final payment = detail.payment;
                    final payable = payment?.amountDue ??
                        orders
                            .where((o) => o.status != OrderStatus.cancelled)
                            .fold<double>(0, (s, o) => s + o.grandTotal);
                    final paid = payment?.status == PaymentStatus.paid;

                    return RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(sessionDetailProvider),
                      child: ListView(
                        padding: AppSpacing.screenPadding,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: AppSpacing.radiusLg,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: paid
                                    ? const [
                                        AppColors.sage,
                                        Color(0xFF1F4D3A),
                                      ]
                                    : const [
                                        AppColors.ink,
                                        AppColors.inkSoft,
                                      ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paid ? 'Payment received' : 'Total payable',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  CurrencyFormatter.format(payable),
                                  style: textTheme.displayMedium?.copyWith(
                                    color: Colors.white,
                                    fontSize: 36,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    paid
                                        ? 'Thank you — enjoy your meal'
                                        : 'Please pay at the counter',
                                    style: textTheme.titleSmall?.copyWith(
                                      color: AppColors.saffron,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const SectionHeader(
                            title: 'Orders',
                            subtitle: 'Live status updates from the kitchen',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (orders.isEmpty)
                            AppSurface(
                              child: Text(
                                'No orders yet. Browse the menu to get started.',
                                style: textTheme.bodyMedium,
                              ),
                            )
                          else
                            ...orders.map(_OrderCard.new),
                          const SizedBox(height: AppSpacing.lg),
                          OutlinedButton.icon(
                            onPressed: () =>
                                context.go(AppRoutes.customerMenu),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Order more'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard(this.order);

  final Order order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id}',
                    style: textTheme.titleMedium,
                  ),
                ),
                _statusBadge(order.status),
              ],
            ),
            const SizedBox(height: 10),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${item.quantity}× ${item.nameSnapshot}',
                  style: textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              CurrencyFormatter.format(order.grandTotal),
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.saffronDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  StatusBadge _statusBadge(OrderStatus status) {
    final label = status.name[0].toUpperCase() + status.name.substring(1);
    final color = switch (status) {
      OrderStatus.pending => AppColors.statusPending,
      OrderStatus.accepted || OrderStatus.preparing =>
        AppColors.statusPreparing,
      OrderStatus.ready || OrderStatus.served => AppColors.statusReady,
      OrderStatus.completed => AppColors.statusPaid,
      OrderStatus.cancelled => AppColors.statusCancelled,
    };
    return StatusBadge(label: label, color: color);
  }
}
