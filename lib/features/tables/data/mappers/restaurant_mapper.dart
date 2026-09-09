import '../../../../core/network/json_helpers.dart';
import '../../domain/entities/restaurant.dart';

abstract final class RestaurantMapper {
  static Restaurant fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: JsonHelpers.id(json['id']),
      name: JsonHelpers.asString(json['name']) ?? '',
      currencyCode:
          JsonHelpers.asString(
            JsonHelpers.pick(json, ['currencyCode', 'currency_code']),
          ) ??
          'INR',
      taxRate: JsonHelpers.asDouble(
        JsonHelpers.pick(json, ['taxRate', 'tax_rate']),
      ),
      serviceChargeRate: JsonHelpers.asDouble(
        JsonHelpers.pick(json, ['serviceChargeRate', 'service_charge_rate']),
      ),
      isActive: JsonHelpers.asBool(
        JsonHelpers.pick(json, ['isActive', 'is_active']),
        true,
      ),
    );
  }
}
