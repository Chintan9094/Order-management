import '../../shared/domain/enums.dart';

abstract final class PaymentStatusMachine {
  static const Map<PaymentStatus, Set<PaymentStatus>> _transitions = {
    PaymentStatus.unpaid: {
      PaymentStatus.paymentPending,
      PaymentStatus.paid,
    },
    PaymentStatus.paymentPending: {PaymentStatus.paid},
    PaymentStatus.paid: {},
  };

  static bool canTransition(PaymentStatus from, PaymentStatus to) {
    return _transitions[from]?.contains(to) ?? false;
  }

  static bool canMarkPaid(PaymentStatus current) {
    return canTransition(current, PaymentStatus.paid);
  }

  static void assertTransition(PaymentStatus from, PaymentStatus to) {
    if (!canTransition(from, to)) {
      throw StateError('Invalid payment status transition: $from → $to');
    }
  }
}
