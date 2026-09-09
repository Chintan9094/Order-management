import 'package:flutter_test/flutter_test.dart';
import 'package:order_management/features/payments/domain/payment_status_machine.dart';
import 'package:order_management/features/shared/domain/enums.dart';

void main() {
  group('PaymentStatusMachine', () {
    test('unpaid can be marked paid', () {
      expect(PaymentStatusMachine.canMarkPaid(PaymentStatus.unpaid), isTrue);
    });

    test('paid cannot be marked paid again', () {
      expect(PaymentStatusMachine.canMarkPaid(PaymentStatus.paid), isFalse);
    });

    test('rejects paid → unpaid', () {
      expect(
        PaymentStatusMachine.canTransition(
          PaymentStatus.paid,
          PaymentStatus.unpaid,
        ),
        isFalse,
      );
    });
  });
}
