import '../../../../core/network/json_helpers.dart';
import '../../../shared/data/enum_parsers.dart';
import '../../../shared/domain/enums.dart';
import '../../domain/entities/restaurant_table.dart';

abstract final class RestaurantTableMapper {
  static RestaurantTable fromJson(Map<String, dynamic> json) {
    final statusRaw = JsonHelpers.pick(json, [
      'status',
      'derivedStatus',
      'derived_status',
      'displayStatus',
    ]);

    String? openSessionId;
    String? openPaymentId;
    PaymentStatus? openPaymentStatus;
    double? openPaymentAmountDue;

    final openSessionRaw =
        JsonHelpers.pick(json, ['openSession', 'open_session']);
    if (openSessionRaw != null) {
      final session = JsonHelpers.asMap(openSessionRaw);
      openSessionId = JsonHelpers.optionalId(session['id']);
      final paymentRaw = session['payment'];
      if (paymentRaw != null) {
        final payment = JsonHelpers.asMap(paymentRaw);
        openPaymentId = JsonHelpers.optionalId(payment['id']);
        openPaymentStatus = EnumParsers.paymentStatus(payment['status']);
        openPaymentAmountDue = JsonHelpers.asDouble(
          JsonHelpers.pick(payment, ['amountDue', 'amount_due']),
        );
      }
    }

    return RestaurantTable(
      id: JsonHelpers.id(json['id']),
      restaurantId: JsonHelpers.id(
        JsonHelpers.pick(json, ['restaurantId', 'restaurant_id']),
      ),
      label: JsonHelpers.asString(json['label']) ?? '',
      publicToken: JsonHelpers.asString(
            JsonHelpers.pick(json, ['publicToken', 'public_token']),
          ) ??
          '',
      capacity: json['capacity'] == null
          ? null
          : JsonHelpers.asInt(json['capacity']),
      isActive: JsonHelpers.asBool(
        JsonHelpers.pick(json, ['isActive', 'is_active']),
        true,
      ),
      displayStatus: EnumParsers.tableDisplayStatus(statusRaw),
      openSessionId: openSessionId,
      openPaymentId: openPaymentId,
      openPaymentStatus: openPaymentStatus,
      openPaymentAmountDue: openPaymentAmountDue,
    );
  }
}
