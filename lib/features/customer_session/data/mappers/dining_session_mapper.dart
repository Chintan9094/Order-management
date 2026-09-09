import '../../../../core/network/json_helpers.dart';
import '../../../shared/data/enum_parsers.dart';
import '../../domain/entities/dining_session.dart';

abstract final class DiningSessionMapper {
  static DiningSession fromJson(Map<String, dynamic> json) {
    return DiningSession(
      id: JsonHelpers.id(json['id']),
      restaurantId: JsonHelpers.id(
        JsonHelpers.pick(json, ['restaurantId', 'restaurant_id']),
      ),
      tableId: JsonHelpers.id(
        JsonHelpers.pick(json, ['tableId', 'table_id']),
      ),
      status: EnumParsers.diningSessionStatus(json['status']),
      startedAt: JsonHelpers.asDateTime(
            JsonHelpers.pick(json, ['startedAt', 'started_at']),
          ) ??
          DateTime.now(),
      closedAt: JsonHelpers.asDateTime(
        JsonHelpers.pick(json, ['closedAt', 'closed_at']),
      ),
      allowsNewOrders: JsonHelpers.asBool(
        JsonHelpers.pick(json, ['allowsNewOrders', 'allows_new_orders']),
        true,
      ),
    );
  }
}
