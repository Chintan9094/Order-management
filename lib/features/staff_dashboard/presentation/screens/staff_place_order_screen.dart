import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../menu/domain/entities/menu.dart';
import '../../../orders/domain/repositories/order_repository.dart';
import '../../../tables/domain/entities/restaurant_table.dart';
import '../providers/staff_providers.dart';

/// Admin / manager / waiter places an order for a guest at any table.
class StaffPlaceOrderScreen extends ConsumerStatefulWidget {
  const StaffPlaceOrderScreen({super.key});

  @override
  ConsumerState<StaffPlaceOrderScreen> createState() =>
      _StaffPlaceOrderScreenState();
}

class _StaffPlaceOrderScreenState extends ConsumerState<StaffPlaceOrderScreen> {
  RestaurantTable? _table;
  final Map<String, int> _qtyByItemId = {};
  bool _submitting = false;

  int get _cartCount => _qtyByItemId.values.fold(0, (a, b) => a + b);

  double _cartTotal(MenuCatalog catalog) {
    var total = 0.0;
    for (final entry in _qtyByItemId.entries) {
      MenuItem? item;
      for (final i in catalog.items) {
        if (i.id == entry.key) {
          item = i;
          break;
        }
      }
      if (item != null) total += item.price * entry.value;
    }
    return total;
  }

  void _setQty(String itemId, int qty) {
    setState(() {
      if (qty <= 0) {
        _qtyByItemId.remove(itemId);
      } else {
        _qtyByItemId[itemId] = qty;
      }
    });
  }

  Future<void> _submit(MenuCatalog catalog) async {
    final table = _table;
    if (table == null || _qtyByItemId.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      final items = _qtyByItemId.entries
          .map(
            (e) => PlaceOrderItemRequest(
              menuItemId: e.key,
              quantity: e.value,
            ),
          )
          .toList();

      await ref.read(orderRepositoryProvider).placeStaffOrderForTable(
            tableId: table.id,
            items: items,
            idempotencyKey: const Uuid().v4(),
          );

      ref.invalidate(staffOrdersProvider);
      ref.invalidate(staffTablesProvider);
      ref.invalidate(staffDashboardProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed for ${table.label}')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(staffTablesProvider);
    final menuAsync = ref.watch(staffMenuProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order for table'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: tablesAsync.when(
        loading: () => const AppLoading(message: 'Loading tables…'),
        error: (e, _) => AppErrorView(
          error: e,
          onRetry: () => ref.invalidate(staffTablesProvider),
        ),
        data: (tables) {
          final active = tables.where((t) => t.isActive).toList();
          if (active.isEmpty) {
            return const AppEmptyState(
              title: 'No tables',
              subtitle: 'Add a table first, then place an order.',
              icon: Icons.table_restaurant_outlined,
            );
          }

          return menuAsync.when(
            loading: () => const AppLoading(message: 'Loading menu…'),
            error: (e, _) => AppErrorView(
              error: e,
              onRetry: () => ref.invalidate(staffMenuProvider),
            ),
            data: (catalog) {
              final items = catalog.items
                  .where((i) => i.isActive && i.isAvailable)
                  .toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Place an order for a guest who cannot scan the QR.',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _table?.id,
                          decoration: const InputDecoration(
                            labelText: 'Table',
                            border: OutlineInputBorder(),
                          ),
                          items: active
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.label),
                                ),
                              )
                              .toList(),
                          onChanged: (id) {
                            setState(() {
                              _table = active.firstWhere((t) => t.id == id);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: items.isEmpty
                        ? const AppEmptyState(
                            title: 'No menu items',
                            subtitle: 'Add dishes in the Menu tab first.',
                            icon: Icons.restaurant_menu_outlined,
                          )
                        : ListView.separated(
                            padding: AppSpacing.screenPadding,
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final qty = _qtyByItemId[item.id] ?? 0;
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: AppSpacing.radiusMd,
                                  border: Border.all(color: AppColors.outline),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: textTheme.titleMedium,
                                          ),
                                          Text(
                                            CurrencyFormatter.format(item.price),
                                            style: textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (qty == 0)
                                      FilledButton(
                                        onPressed: _table == null
                                            ? null
                                            : () => _setQty(item.id, 1),
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size(0, 36),
                                          backgroundColor: AppColors.saffron,
                                        ),
                                        child: const Text('Add'),
                                      )
                                    else
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                _setQty(item.id, qty - 1),
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                            ),
                                          ),
                                          Text(
                                            '$qty',
                                            style: textTheme.titleMedium,
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                _setQty(item.id, qty + 1),
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: FilledButton(
                        onPressed: _table == null ||
                                _cartCount == 0 ||
                                _submitting
                            ? null
                            : () => _submit(catalog),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: AppColors.ink,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _cartCount == 0
                                    ? 'Select items'
                                    : 'Place order · ${CurrencyFormatter.format(_cartTotal(catalog))}',
                              ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
