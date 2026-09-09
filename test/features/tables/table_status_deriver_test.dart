import 'package:flutter_test/flutter_test.dart';
import 'package:order_management/features/customer_session/domain/entities/dining_session.dart';
import 'package:order_management/features/orders/domain/entities/order.dart';
import 'package:order_management/features/payments/domain/entities/payment.dart';
import 'package:order_management/features/shared/domain/enums.dart';
import 'package:order_management/features/tables/domain/table_status_deriver.dart';

Order _order(OrderStatus status) {
  final now = DateTime(2026, 1, 1);
  return Order(
    id: 'o1',
    sessionId: 's1',
    restaurantId: 'r1',
    tableId: 't1',
    status: status,
    items: const [],
    subtotal: 100,
    tax: 0,
    serviceCharge: 0,
    grandTotal: 100,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('TableStatusDeriver', () {
    test('no session → available', () {
      expect(TableStatusDeriver.derive(), TableDisplayStatus.available);
    });

    test('open session without orders → occupied', () {
      final session = DiningSession(
        id: 's1',
        restaurantId: 'r1',
        tableId: 't1',
        status: DiningSessionStatus.open,
        startedAt: DateTime(2026, 1, 1),
      );
      expect(
        TableStatusDeriver.derive(session: session),
        TableDisplayStatus.occupied,
      );
    });

    test('pending order → orderPlaced', () {
      final session = DiningSession(
        id: 's1',
        restaurantId: 'r1',
        tableId: 't1',
        status: DiningSessionStatus.open,
        startedAt: DateTime(2026, 1, 1),
      );
      expect(
        TableStatusDeriver.derive(
          session: session,
          orders: [_order(OrderStatus.pending)],
        ),
        TableDisplayStatus.orderPlaced,
      );
    });

    test('served + unpaid → paymentPending', () {
      final session = DiningSession(
        id: 's1',
        restaurantId: 'r1',
        tableId: 't1',
        status: DiningSessionStatus.open,
        startedAt: DateTime(2026, 1, 1),
      );
      expect(
        TableStatusDeriver.derive(
          session: session,
          orders: [_order(OrderStatus.served)],
          payment: const Payment(
            id: 'p1',
            sessionId: 's1',
            status: PaymentStatus.unpaid,
            amountDue: 100,
          ),
        ),
        TableDisplayStatus.paymentPending,
      );
    });

    test('paid session → paid display', () {
      final session = DiningSession(
        id: 's1',
        restaurantId: 'r1',
        tableId: 't1',
        status: DiningSessionStatus.open,
        startedAt: DateTime(2026, 1, 1),
      );
      expect(
        TableStatusDeriver.derive(
          session: session,
          orders: [_order(OrderStatus.completed)],
          payment: const Payment(
            id: 'p1',
            sessionId: 's1',
            status: PaymentStatus.paid,
            amountDue: 100,
            amountPaid: 100,
          ),
        ),
        TableDisplayStatus.paid,
      );
    });

    test('cannot become available while unpaid active session', () {
      final session = DiningSession(
        id: 's1',
        restaurantId: 'r1',
        tableId: 't1',
        status: DiningSessionStatus.open,
        startedAt: DateTime(2026, 1, 1),
      );
      expect(
        TableStatusDeriver.canBecomeAvailable(
          session: session,
          orders: [_order(OrderStatus.preparing)],
          payment: const Payment(
            id: 'p1',
            sessionId: 's1',
            status: PaymentStatus.unpaid,
            amountDue: 100,
          ),
        ),
        isFalse,
      );
    });
  });
}
