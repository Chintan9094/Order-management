import '../../../../core/network/json_helpers.dart';
import '../../../shared/data/enum_parsers.dart';
import '../../domain/entities/payment.dart';

abstract final class PaymentMapper {
  static Payment fromJson(Map<String, dynamic> json) {
    return Payment(
      id: JsonHelpers.id(json['id']),
      sessionId: JsonHelpers.id(
        JsonHelpers.pick(json, [
          'diningSessionId',
          'dining_session_id',
          'sessionId',
          'session_id',
        ]),
      ),
      status: EnumParsers.paymentStatus(json['status']),
      amountDue: JsonHelpers.asDouble(
        JsonHelpers.pick(json, ['amountDue', 'amount_due']),
      ),
      amountPaid: JsonHelpers.pick(json, ['amountPaid', 'amount_paid']) == null
          ? null
          : JsonHelpers.asDouble(
              JsonHelpers.pick(json, ['amountPaid', 'amount_paid']),
            ),
      paidAt: JsonHelpers.asDateTime(
        JsonHelpers.pick(json, ['paidAt', 'paid_at']),
      ),
      markedByStaffId: JsonHelpers.optionalId(
        JsonHelpers.pick(json, ['markedByStaffId', 'marked_by_staff_id']),
      ),
    );
  }
}
