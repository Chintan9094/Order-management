import '../../../../core/network/json_helpers.dart';
import '../../../shared/data/enum_parsers.dart';
import '../../domain/entities/order.dart';

abstract final class OrderMapper {
  static OrderItem itemFromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: JsonHelpers.id(json['id']),
      orderId: JsonHelpers.id(
        JsonHelpers.pick(json, ['orderId', 'order_id']),
      ),
      menuItemId: JsonHelpers.optionalId(
        JsonHelpers.pick(json, ['menuItemId', 'menu_item_id']),
      ),
      nameSnapshot: JsonHelpers.asString(
            JsonHelpers.pick(json, ['name', 'nameSnapshot', 'name_snapshot']),
          ) ??
          '',
      unitPriceSnapshot: JsonHelpers.asDouble(
        JsonHelpers.pick(json, [
          'unitPrice',
          'unit_price',
          'unitPriceSnapshot',
          'unit_price_snapshot',
        ]),
      ),
      quantity: JsonHelpers.asInt(json['quantity'], 1),
      lineTotal: JsonHelpers.asDouble(
        JsonHelpers.pick(json, ['lineTotal', 'line_total']),
      ),
      note: JsonHelpers.asString(json['note']),
    );
  }

  static Order fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final items = <OrderItem>[];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        items.add(itemFromJson(JsonHelpers.asMap(item)));
      }
    }

    return Order(
      id: JsonHelpers.id(json['id']),
      sessionId: JsonHelpers.id(
        JsonHelpers.pick(json, [
          'diningSessionId',
          'dining_session_id',
          'sessionId',
          'session_id',
        ]),
      ),
      restaurantId: JsonHelpers.id(
        JsonHelpers.pick(json, ['restaurantId', 'restaurant_id']),
      ),
      tableId: JsonHelpers.id(
        JsonHelpers.pick(json, ['tableId', 'table_id']),
      ),
      status: EnumParsers.orderStatus(json['status']),
      items: items,
      subtotal: JsonHelpers.asDouble(json['subtotal']),
      tax: JsonHelpers.asDouble(json['tax']),
      serviceCharge: JsonHelpers.asDouble(
        JsonHelpers.pick(json, ['serviceCharge', 'service_charge']),
      ),
      grandTotal: JsonHelpers.asDouble(
        JsonHelpers.pick(json, ['grandTotal', 'grand_total']),
      ),
      notes: JsonHelpers.asString(json['notes']),
      createdAt: JsonHelpers.asDateTime(
            JsonHelpers.pick(json, ['createdAt', 'created_at']),
          ) ??
          DateTime.now(),
      updatedAt: JsonHelpers.asDateTime(
            JsonHelpers.pick(json, ['updatedAt', 'updated_at']),
          ) ??
          DateTime.now(),
    );
  }
}
