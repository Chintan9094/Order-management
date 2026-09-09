import '../../../../core/network/json_helpers.dart';
import '../../../shared/data/enum_parsers.dart';
import '../../domain/entities/menu.dart';

abstract final class MenuMapper {
  static MenuItem itemFromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: JsonHelpers.id(json['id']),
      restaurantId: JsonHelpers.id(
        JsonHelpers.pick(json, ['restaurantId', 'restaurant_id']),
      ),
      categoryId: JsonHelpers.id(
        JsonHelpers.pick(json, ['categoryId', 'category_id']),
      ),
      name: JsonHelpers.asString(json['name']) ?? '',
      description: JsonHelpers.asString(json['description']),
      price: JsonHelpers.asDouble(json['price']),
      imageUrl: JsonHelpers.asString(
        JsonHelpers.pick(json, ['imageUrl', 'image_url']),
      ),
      diet: EnumParsers.diet(json['diet']),
      prepMinutes: JsonHelpers.pick(json, ['prepMinutes', 'prep_minutes']) ==
              null
          ? null
          : JsonHelpers.asInt(
              JsonHelpers.pick(json, ['prepMinutes', 'prep_minutes']),
            ),
      sortOrder: JsonHelpers.asInt(
        JsonHelpers.pick(json, ['sortOrder', 'sort_order']),
      ),
      isAvailable: JsonHelpers.asBool(
        JsonHelpers.pick(json, ['isAvailable', 'is_available']),
        true,
      ),
      isActive: JsonHelpers.asBool(
        JsonHelpers.pick(json, ['isActive', 'is_active']),
        true,
      ),
    );
  }

  static MenuCategory categoryFromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: JsonHelpers.id(json['id']),
      restaurantId: JsonHelpers.id(
        JsonHelpers.pick(json, ['restaurantId', 'restaurant_id']),
      ),
      name: JsonHelpers.asString(json['name']) ?? '',
      sortOrder: JsonHelpers.asInt(
        JsonHelpers.pick(json, ['sortOrder', 'sort_order']),
      ),
      isActive: JsonHelpers.asBool(
        JsonHelpers.pick(json, ['isActive', 'is_active']),
        true,
      ),
    );
  }

  static MenuCatalog catalogFromJson(Map<String, dynamic> json) {
    final categories = <MenuCategory>[];
    final items = <MenuItem>[];
    final categoriesRaw = json['categories'];
    if (categoriesRaw is List) {
      for (final raw in categoriesRaw) {
        final map = JsonHelpers.asMap(raw);
        final category = categoryFromJson(map);
        categories.add(category);
        final nestedItems = map['items'];
        if (nestedItems is List) {
          for (final itemRaw in nestedItems) {
            final itemMap = JsonHelpers.asMap(itemRaw);
            // Ensure categoryId is set even if API omits it on nested items.
            if (itemMap['categoryId'] == null &&
                itemMap['category_id'] == null) {
              itemMap['categoryId'] = category.id;
            }
            if (itemMap['restaurantId'] == null &&
                itemMap['restaurant_id'] == null) {
              itemMap['restaurantId'] = category.restaurantId;
            }
            items.add(itemFromJson(itemMap));
          }
        }
      }
    }

    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return MenuCatalog(
      restaurantId: JsonHelpers.id(
        JsonHelpers.pick(json, ['restaurantId', 'restaurant_id']),
      ),
      currencyCode:
          JsonHelpers.asString(
            JsonHelpers.pick(json, ['currencyCode', 'currency_code']),
          ) ??
          'INR',
      categories: categories,
      items: items,
    );
  }
}
