import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../menu/domain/entities/menu.dart';
import '../../../shared/domain/enums.dart';
import '../../../shared/domain/staff_permissions.dart';
import '../providers/staff_providers.dart';

class StaffMenuTab extends ConsumerWidget {
  const StaffMenuTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffMenuProvider);
    final canManage = ref
            .watch(authControllerProvider)
            .user
            ?.hasPermission(StaffPermissions.manageMenu) ??
        false;

    return async.when(
      loading: () => const AppLoading(message: 'Loading menu…'),
      error: (e, _) => AppErrorView(
        error: e,
        onRetry: () => ref.invalidate(staffMenuProvider),
      ),
      data: (catalog) {
        return Stack(
          children: [
            if (catalog.categories.isEmpty)
              AppEmptyState(
                title: 'No menu items available',
                subtitle: canManage
                    ? 'Add a category, then add dishes.'
                    : 'Ask an admin or manager to set up the menu.',
                icon: Icons.restaurant_menu_outlined,
              )
            else
              RefreshIndicator(
                onRefresh: () async => ref.invalidate(staffMenuProvider),
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    canManage ? 88 : AppSpacing.md,
                  ),
                  itemCount: catalog.categories.length,
                  itemBuilder: (context, index) {
                    final category = catalog.categories[index];
                    final items = catalog.items
                        .where((i) => i.categoryId == category.id)
                        .toList()
                      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.name,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                              ),
                              if (canManage) ...[
                                IconButton(
                                  tooltip: 'Edit category',
                                  onPressed: () => _showCategoryEditor(
                                    context,
                                    ref,
                                    category: category,
                                  ),
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                ),
                                IconButton(
                                  tooltip: 'Delete category',
                                  onPressed: () => _confirmDeleteCategory(
                                    context,
                                    ref,
                                    category,
                                  ),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  color: AppColors.danger,
                                ),
                                IconButton(
                                  tooltip: 'Add item',
                                  onPressed: () => _showItemEditor(
                                    context,
                                    ref,
                                    categories: catalog.categories,
                                    categoryId: category.id,
                                  ),
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: AppColors.saffronDark,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'No items in this category',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppSurface(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.mistDeep,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.dinner_dining_rounded,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        Text(
                                          [
                                            CurrencyFormatter.format(item.price),
                                            if (!item.isAvailable) 'Unavailable',
                                            _dietLabel(item.diet),
                                          ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (canManage) ...[
                                    IconButton(
                                      tooltip: 'Edit',
                                      onPressed: () => _showItemEditor(
                                        context,
                                        ref,
                                        categories: catalog.categories,
                                        item: item,
                                      ),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () => _confirmDeleteItem(
                                        context,
                                        ref,
                                        item,
                                      ),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                      ),
                                      color: AppColors.danger,
                                    ),
                                  ] else
                                    Text(
                                      CurrencyFormatter.format(item.price),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: AppColors.saffronDark,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (canManage)
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'add-category',
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      onPressed: () => _showCategoryEditor(context, ref),
                      icon: const Icon(Icons.category_outlined),
                      label: const Text('Category'),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.extended(
                      heroTag: 'add-menu-item',
                      backgroundColor: AppColors.saffron,
                      onPressed: catalog.categories.isEmpty
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Add a category first'),
                                ),
                              );
                            }
                          : () => _showItemEditor(
                                context,
                                ref,
                                categories: catalog.categories,
                              ),
                      icon: const Icon(Icons.add),
                      label: const Text('Item'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  String? _dietLabel(MenuItemDiet diet) {
    return switch (diet) {
      MenuItemDiet.veg => 'Veg',
      MenuItemDiet.nonVeg => 'Non-veg',
      MenuItemDiet.egg => 'Egg',
      MenuItemDiet.vegan => 'Vegan',
      MenuItemDiet.unknown => null,
    };
  }

  Future<void> _showCategoryEditor(
    BuildContext context,
    WidgetRef ref, {
    MenuCategory? category,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _CategoryEditorDialog(initialName: category?.name),
    );
    if (result == null || !context.mounted) return;

    try {
      final repo = ref.read(menuRepositoryProvider);
      if (category != null) {
        await repo.updateCategory(
          MenuCategory(
            id: category.id,
            restaurantId: category.restaurantId,
            name: result,
            sortOrder: category.sortOrder,
            isActive: category.isActive,
          ),
        );
      } else {
        await repo.createCategory(name: result);
      }
      ref.invalidate(staffMenuProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              category != null ? 'Category updated' : 'Category added',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.userMessage(e))),
        );
      }
    }
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    MenuCategory category,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove category?'),
        content: Text('${category.name} will be hidden from the menu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(menuRepositoryProvider).deactivateCategory(category.id);
      ref.invalidate(staffMenuProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${category.name} removed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.userMessage(e))),
        );
      }
    }
  }

  Future<void> _showItemEditor(
    BuildContext context,
    WidgetRef ref, {
    required List<MenuCategory> categories,
    MenuItem? item,
    String? categoryId,
  }) async {
    final draft = await showDialog<_MenuItemDraft>(
      context: context,
      builder: (ctx) => _MenuItemEditorDialog(
        categories: categories,
        item: item,
        initialCategoryId: categoryId,
      ),
    );
    if (draft == null || !context.mounted) return;

    try {
      final repo = ref.read(menuRepositoryProvider);
      if (item != null) {
        await repo.updateMenuItem(
          MenuItem(
            id: item.id,
            restaurantId: item.restaurantId,
            categoryId: draft.categoryId,
            name: draft.name,
            price: draft.price,
            description: draft.description,
            diet: draft.diet,
            prepMinutes: draft.prepMinutes,
            sortOrder: item.sortOrder,
            isAvailable: draft.isAvailable,
            isActive: item.isActive,
          ),
        );
      } else {
        await repo.createMenuItem(
          categoryId: draft.categoryId,
          name: draft.name,
          price: draft.price,
          description: draft.description,
          diet: draft.diet,
          prepMinutes: draft.prepMinutes,
          isAvailable: draft.isAvailable,
        );
      }
      ref.invalidate(staffMenuProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(item != null ? 'Item updated' : 'Item added'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.userMessage(e))),
        );
      }
    }
  }

  Future<void> _confirmDeleteItem(
    BuildContext context,
    WidgetRef ref,
    MenuItem item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('${item.name} will be hidden from the menu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(menuRepositoryProvider).deactivateMenuItem(item.id);
      ref.invalidate(staffMenuProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} removed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.userMessage(e))),
        );
      }
    }
  }
}

class _MenuItemDraft {
  const _MenuItemDraft({
    required this.categoryId,
    required this.name,
    required this.price,
    required this.diet,
    required this.isAvailable,
    this.description,
    this.prepMinutes,
  });

  final String categoryId;
  final String name;
  final double price;
  final String? description;
  final MenuItemDiet diet;
  final int? prepMinutes;
  final bool isAvailable;
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({this.initialName});

  final String? initialName;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit category' : 'Add category'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Name'),
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop(context, _nameCtrl.text.trim());
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.saffron),
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

class _MenuItemEditorDialog extends StatefulWidget {
  const _MenuItemEditorDialog({
    required this.categories,
    this.item,
    this.initialCategoryId,
  });

  final List<MenuCategory> categories;
  final MenuItem? item;
  final String? initialCategoryId;

  @override
  State<_MenuItemEditorDialog> createState() => _MenuItemEditorDialogState();
}

class _MenuItemEditorDialogState extends State<_MenuItemEditorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _prepCtrl;
  late String _categoryId;
  late MenuItemDiet _diet;
  late bool _isAvailable;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _priceCtrl = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(0) : '',
    );
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _prepCtrl = TextEditingController(text: item?.prepMinutes?.toString() ?? '');
    _categoryId = item?.categoryId ??
        widget.initialCategoryId ??
        widget.categories.first.id;
    _diet = item?.diet == MenuItemDiet.unknown || item?.diet == null
        ? MenuItemDiet.veg
        : item!.diet;
    _isAvailable = item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _prepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit item' : 'Add item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _categoryId = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Price (₹)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MenuItemDiet>(
                initialValue: _diet,
                decoration: const InputDecoration(labelText: 'Diet'),
                items: const [
                  DropdownMenuItem(
                    value: MenuItemDiet.veg,
                    child: Text('Veg'),
                  ),
                  DropdownMenuItem(
                    value: MenuItemDiet.nonVeg,
                    child: Text('Non-veg'),
                  ),
                  DropdownMenuItem(
                    value: MenuItemDiet.egg,
                    child: Text('Egg'),
                  ),
                  DropdownMenuItem(
                    value: MenuItemDiet.vegan,
                    child: Text('Vegan'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _diet = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prepCtrl,
                decoration: const InputDecoration(
                  labelText: 'Prep minutes (optional)',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available to order'),
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            final description = _descCtrl.text.trim();
            Navigator.pop(
              context,
              _MenuItemDraft(
                categoryId: _categoryId,
                name: _nameCtrl.text.trim(),
                price: double.parse(_priceCtrl.text.trim()),
                description: description.isEmpty ? null : description,
                diet: _diet,
                prepMinutes: int.tryParse(_prepCtrl.text.trim()),
                isAvailable: _isAvailable,
              ),
            );
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.saffron),
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
