import 'package:flutter_test/flutter_test.dart';
import 'package:order_management/features/orders/domain/order_status_machine.dart';
import 'package:order_management/features/shared/domain/enums.dart';

void main() {
  group('OrderStatusMachine', () {
    test('allows pending → accepted', () {
      expect(
        OrderStatusMachine.canTransition(
          OrderStatus.pending,
          OrderStatus.accepted,
        ),
        isTrue,
      );
    });

    test('rejects pending → ready', () {
      expect(
        OrderStatusMachine.canTransition(
          OrderStatus.pending,
          OrderStatus.ready,
        ),
        isFalse,
      );
    });

    test('allows full happy path', () {
      const path = [
        OrderStatus.pending,
        OrderStatus.accepted,
        OrderStatus.preparing,
        OrderStatus.ready,
        OrderStatus.served,
        OrderStatus.completed,
      ];
      for (var i = 0; i < path.length - 1; i++) {
        expect(
          OrderStatusMachine.canTransition(path[i], path[i + 1]),
          isTrue,
          reason: '${path[i]} → ${path[i + 1]}',
        );
      }
    });

    test('cancel allowed for pending by anyone', () {
      expect(
        OrderStatusMachine.canCancel(
          current: OrderStatus.pending,
          isManagerOrAbove: false,
        ),
        isTrue,
      );
    });

    test('cancel accepted only for manager+', () {
      expect(
        OrderStatusMachine.canCancel(
          current: OrderStatus.accepted,
          isManagerOrAbove: false,
        ),
        isFalse,
      );
      expect(
        OrderStatusMachine.canCancel(
          current: OrderStatus.accepted,
          isManagerOrAbove: true,
        ),
        isTrue,
      );
    });

    test('cannot cancel preparing', () {
      expect(
        OrderStatusMachine.canCancel(
          current: OrderStatus.preparing,
          isManagerOrAbove: true,
        ),
        isFalse,
      );
    });
  });
}
