import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../routing/routes.dart';
import '../../../customer_session/presentation/providers/customer_session_providers.dart';
import '../../../menu/domain/entities/menu.dart';
import '../../../shared/domain/enums.dart';
import '../providers/menu_providers.dart';

class CustomerMenuScreen extends ConsumerStatefulWidget {
  const CustomerMenuScreen({super.key});

  @override
  ConsumerState<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends ConsumerState<CustomerMenuScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeCustomerSessionProvider);
    final menuAsync = ref.watch(menuCatalogProvider);
    final cart = ref.watch(cartControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    if (session == null) {
      return Scaffold(
        body: PageBackground(
          child: AppErrorView(
            error: 'No active table session. Enter a table code to start.',
            onRetry: () => context.go(AppRoutes.enterTableCode),
          ),
        ),
      );
    }

    return Scaffold(
      body: PageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.restaurantName,
                            style: textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.table_restaurant_rounded,
                                size: 16,
                                color: AppColors.saffronDark,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                session.tableLabel,
                                style: textTheme.titleSmall?.copyWith(
                                  color: AppColors.saffronDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => context.push(AppRoutes.customerSession),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.ink,
                      ),
                      icon: const Icon(Icons.receipt_long_rounded),
                      tooltip: 'Your orders',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: menuAsync.when(
                  loading: () => const AppLoading(message: 'Loading menu…'),
                  error: (e, _) => AppErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(menuCatalogProvider),
                  ),
                  data: (catalog) {
                    final categories = catalog.categories;
                    final selectedId = _selectedCategoryId ??
                        (categories.isNotEmpty ? categories.first.id : null);
                    final items = selectedId == null
                        ? catalog.items.where((i) => i.isOrderable).toList()
                        : catalog.itemsForCategory(selectedId);

                    return Column(
                      children: [
                        if (categories.isNotEmpty)
                          SizedBox(
                            height: 48,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                final selected = category.id == selectedId;
                                return ChoiceChip(
                                  label: Text(category.name),
                                  selected: selected,
                                  onSelected: (_) {
                                    setState(
                                      () => _selectedCategoryId = category.id,
                                    );
                                  },
                                  showCheckmark: false,
                                  selectedColor: AppColors.ink,
                                  backgroundColor: AppColors.surface,
                                  labelStyle: textTheme.labelMedium?.copyWith(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.ink
                                        : AppColors.outline,
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        Expanded(
                          child: items.isEmpty
                              ? const Center(
                                  child: Text('No items in this category.'),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    8,
                                    20,
                                    120,
                                  ),
                                  itemCount: items.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return _MenuItemCard(
                                      item: item,
                                      onAdd: () {
                                        ref
                                            .read(
                                              cartControllerProvider.notifier,
                                            )
                                            .addItem(item);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('${item.name} added'),
                                            duration: const Duration(
                                              milliseconds: 800,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Material(
                  elevation: 10,
                  shadowColor: AppColors.ink.withValues(alpha: 0.25),
                  borderRadius: AppSpacing.radiusMd,
                  color: AppColors.ink,
                  child: InkWell(
                    borderRadius: AppSpacing.radiusMd,
                    onTap: () => context.push(AppRoutes.customerCart),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.saffron,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${cart.lines.fold<int>(0, (s, l) => s + l.quantity)}',
                              style: textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'View cart',
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(cart.grandTotal),
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item, required this.onAdd});

  final MenuItem item;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final diet = _dietMeta(item.diet);

    return AppSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.mistDeep,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.dinner_dining_rounded,
              color: AppColors.ink.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (diet != null) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: diet.$2,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(item.name, style: textTheme.titleMedium),
                    ),
                  ],
                ),
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.format(item.price),
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.saffronDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: onAdd,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(74, 38),
                        backgroundColor: AppColors.saffron,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, Color)? _dietMeta(MenuItemDiet diet) {
    return switch (diet) {
      MenuItemDiet.veg || MenuItemDiet.vegan => ('Veg', AppColors.sage),
      MenuItemDiet.nonVeg => ('Non-veg', AppColors.danger),
      MenuItemDiet.egg => ('Egg', AppColors.warning),
      MenuItemDiet.unknown => null,
    };
  }
}
