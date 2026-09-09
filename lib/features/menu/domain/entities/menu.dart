import 'package:equatable/equatable.dart';

import '../../../shared/domain/enums.dart';

class MenuCategory extends Equatable {
  const MenuCategory({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String restaurantId;
  final String name;
  final int sortOrder;
  final bool isActive;

  @override
  List<Object?> get props => [id, restaurantId, name, sortOrder, isActive];
}

class MenuItem extends Equatable {
  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.diet = MenuItemDiet.unknown,
    this.prepMinutes,
    this.sortOrder = 0,
    this.isAvailable = true,
    this.isActive = true,
  });

  final String id;
  final String restaurantId;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final MenuItemDiet diet;
  final int? prepMinutes;
  final int sortOrder;
  final bool isAvailable;
  final bool isActive;

  bool get isOrderable => isActive && isAvailable;

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        categoryId,
        name,
        description,
        price,
        imageUrl,
        diet,
        prepMinutes,
        sortOrder,
        isAvailable,
        isActive,
      ];
}

class MenuCatalog extends Equatable {
  const MenuCatalog({
    required this.restaurantId,
    required this.categories,
    required this.items,
    this.currencyCode = 'INR',
  });

  final String restaurantId;
  final String currencyCode;
  final List<MenuCategory> categories;
  final List<MenuItem> items;

  List<MenuItem> itemsForCategory(String categoryId) => items
      .where((i) => i.categoryId == categoryId && i.isOrderable)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  List<Object?> get props => [restaurantId, currencyCode, categories, items];
}
