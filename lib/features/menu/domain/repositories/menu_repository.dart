import '../entities/menu.dart';
import '../../../shared/domain/enums.dart';

abstract class MenuRepository {
  /// Public customer menu (active + available only).
  Future<MenuCatalog> getMenu(String restaurantId);

  /// Staff catalog from /categories + /menu-items (includes inactive for managers).
  Future<MenuCatalog> getStaffMenu(String restaurantId);

  Future<MenuCategory> createCategory({
    required String name,
    int? sortOrder,
  });

  Future<MenuCategory> updateCategory(MenuCategory category);

  Future<void> deactivateCategory(String categoryId);

  Future<MenuItem> createMenuItem({
    required String categoryId,
    required String name,
    required double price,
    String? description,
    MenuItemDiet diet = MenuItemDiet.unknown,
    int? prepMinutes,
    bool isAvailable = true,
  });

  Future<MenuItem> updateMenuItem(MenuItem item);

  Future<void> deactivateMenuItem(String itemId);
}
