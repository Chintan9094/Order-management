import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../routing/routes.dart';
import '../../../customer_session/presentation/providers/customer_session_providers.dart';
import '../../../menu/presentation/providers/menu_providers.dart';

class CustomerCartScreen extends ConsumerWidget {
  const CustomerCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final placeState = ref.watch(placeOrderControllerProvider);
    final session = ref.watch(activeCustomerSessionProvider);
    final textTheme = Theme.of(context).textTheme;
    final placing = placeState.isLoading;

    if (cart.isEmpty) {
      return Scaffold(
        body: PageBackground(
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                Expanded(
                  child: AppEmptyState(
                    title: 'Your cart is empty',
                    subtitle: 'Add dishes from the menu to place an order.',
                    icon: Icons.shopping_bag_outlined,
                    action: FilledButton(
                      onPressed: () => context.go(AppRoutes.customerMenu),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.saffron,
                      ),
                      child: const Text('Browse menu'),
                    ),
                  ),
                ),
              ],
            ),
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
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Text('Your cart', style: textTheme.headlineMedium),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: AppSpacing.screenPadding,
                  children: [
                    ...cart.lines.map((line) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppSurface(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.name,
                                      style: textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(line.unitPrice),
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              QtyStepper(
                                quantity: line.quantity,
                                onChanged: (q) => ref
                                    .read(cartControllerProvider.notifier)
                                    .setQuantity(line.menuItemId, q),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                CurrencyFormatter.format(line.lineTotal),
                                style: textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    AppSurface(
                      color: AppColors.saffronSoft,
                      borderColor: AppColors.saffron.withValues(alpha: 0.25),
                      child: Column(
                        children: [
                          _TotalsRow(label: 'Subtotal', value: cart.subtotal),
                          if (cart.taxAmount > 0)
                            _TotalsRow(
                              label:
                                  'Tax (${(cart.taxRate * 100).toStringAsFixed(0)}%)',
                              value: cart.taxAmount,
                            ),
                          if (cart.serviceChargeAmount > 0)
                            _TotalsRow(
                              label: 'Service charge',
                              value: cart.serviceChargeAmount,
                            ),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          _TotalsRow(
                            label: 'Total',
                            value: cart.grandTotal,
                            emphasize: true,
                          ),
                        ],
                      ),
                    ),
                    if (placeState.hasError) ...[
                      const SizedBox(height: 12),
                      Text(
                        placeState.error.toString(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: FilledButton(
            onPressed: placing || session == null
                ? null
                : () async {
                    final order = await ref
                        .read(placeOrderControllerProvider.notifier)
                        .submit();
                    if (!context.mounted) return;
                    if (order != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Order placed successfully'),
                        ),
                      );
                      context.go(AppRoutes.customerSession);
                    }
                  },
            style: FilledButton.styleFrom(backgroundColor: AppColors.saffron),
            child: placing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Place order · ${CurrencyFormatter.format(cart.grandTotal)}',
                  ),
          ),
        ),
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(CurrencyFormatter.format(value), style: style),
        ],
      ),
    );
  }
}
