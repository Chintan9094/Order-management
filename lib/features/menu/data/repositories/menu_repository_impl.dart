import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception_guard.dart';
import '../../../../core/network/json_helpers.dart';
import '../../../shared/domain/enums.dart';
import '../../domain/entities/menu.dart';
import '../../domain/repositories/menu_repository.dart';
import '../mappers/menu_mapper.dart';

class MenuRepositoryImpl implements MenuRepository {
  MenuRepositoryImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static String _dietApi(MenuItemDiet diet) {
    return switch (diet) {
      MenuItemDiet.veg => 'veg',
      MenuItemDiet.nonVeg => 'nonveg',
      MenuItemDiet.egg => 'egg',
      MenuItemDiet.vegan => 'vegan',
      MenuItemDiet.unknown => 'unknown',
    };
  }

  @override
  Future<MenuCatalog> getMenu(String restaurantId) {
    return guardApiCall(() async {
      final response = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.restaurantMenu(restaurantId),
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      return MenuMapper.catalogFromJson(data);
    });
  }

  @override
  Future<MenuCatalog> getStaffMenu(String restaurantId) {
    return guardApiCall(() async {
      final categoriesRes = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.categories,
      );
      final itemsRes = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.menuItems,
      );

      final categories = JsonHelpers.unwrapDataList(categoriesRes.data)
          .map((e) => MenuMapper.categoryFromJson(JsonHelpers.asMap(e)))
          .where((c) => c.isActive)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final items = JsonHelpers.unwrapDataList(itemsRes.data)
          .map((e) => MenuMapper.itemFromJson(JsonHelpers.asMap(e)))
          .where((i) => i.isActive)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      return MenuCatalog(
        restaurantId: restaurantId,
        categories: categories,
        items: items,
      );
    });
  }

  @override
  Future<MenuCategory> createCategory({
    required String name,
    int? sortOrder,
  }) {
    return guardApiCall(() async {
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.categories,
        data: {
          'name': name,
          if (sortOrder != null) 'sort_order': sortOrder,
        },
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      return MenuMapper.categoryFromJson(data);
    });
  }

  @override
  Future<MenuCategory> updateCategory(MenuCategory category) {
    return guardApiCall(() async {
      final response = await _api.patch<Map<String, dynamic>>(
        ApiEndpoints.category(category.id),
        data: {
          'name': category.name,
          'sort_order': category.sortOrder,
          'is_active': category.isActive,
        },
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      return MenuMapper.categoryFromJson(data);
    });
  }

  @override
  Future<void> deactivateCategory(String categoryId) {
    return guardApiCall(() async {
      await _api.delete(ApiEndpoints.category(categoryId));
    });
  }

  @override
  Future<MenuItem> createMenuItem({
    required String categoryId,
    required String name,
    required double price,
    String? description,
    MenuItemDiet diet = MenuItemDiet.unknown,
    int? prepMinutes,
    bool isAvailable = true,
  }) {
    return guardApiCall(() async {
      final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.menuItems,
        data: {
          'category_id': int.tryParse(categoryId) ?? categoryId,
          'name': name,
          'price': price,
          if (description != null && description.isNotEmpty)
            'description': description,
          'diet': _dietApi(diet),
          if (prepMinutes != null) 'prep_minutes': prepMinutes,
          'is_available': isAvailable,
        },
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      return MenuMapper.itemFromJson(data);
    });
  }

  @override
  Future<MenuItem> updateMenuItem(MenuItem item) {
    return guardApiCall(() async {
      final response = await _api.patch<Map<String, dynamic>>(
        ApiEndpoints.menuItem(item.id),
        data: {
          'category_id': int.tryParse(item.categoryId) ?? item.categoryId,
          'name': item.name,
          'description': item.description,
          'price': item.price,
          'diet': _dietApi(item.diet),
          if (item.prepMinutes != null) 'prep_minutes': item.prepMinutes,
          'sort_order': item.sortOrder,
          'is_available': item.isAvailable,
          'is_active': item.isActive,
        },
      );
      final data = JsonHelpers.unwrapDataMap(response.data);
      return MenuMapper.itemFromJson(data);
    });
  }

  @override
  Future<void> deactivateMenuItem(String itemId) {
    return guardApiCall(() async {
      await _api.delete(ApiEndpoints.menuItem(itemId));
    });
  }
}
