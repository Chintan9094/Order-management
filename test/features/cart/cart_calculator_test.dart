import 'package:flutter_test/flutter_test.dart';
import 'package:order_management/features/cart/domain/cart_calculator.dart';
import 'package:order_management/features/cart/domain/entities/cart.dart';

void main() {
  group('CartCalculator', () {
    const base = Cart(sessionId: 's1');

    test('adds item and computes line total', () {
      final cart = CartCalculator.addItem(
        base,
        menuItemId: 'm1',
        name: 'Paneer Pizza',
        unitPrice: 250,
        quantity: 2,
      );
      expect(cart.lines, hasLength(1));
      expect(cart.lines.first.lineTotal, 500);
      expect(cart.subtotal, 500);
      expect(cart.grandTotal, 500);
    });

    test('merges same item without note', () {
      var cart = CartCalculator.addItem(
        base,
        menuItemId: 'm1',
        name: 'Coke',
        unitPrice: 50,
      );
      cart = CartCalculator.addItem(
        cart,
        menuItemId: 'm1',
        name: 'Coke',
        unitPrice: 50,
        quantity: 2,
      );
      expect(cart.lines, hasLength(1));
      expect(cart.lines.first.quantity, 3);
    });

    test('applies tax and service charge', () {
      final cart = CartCalculator.addItem(
        const Cart(sessionId: 's1', taxRate: 0.05, serviceChargeRate: 0.1),
        menuItemId: 'm1',
        name: 'Item',
        unitPrice: 100,
      );
      expect(cart.subtotal, 100);
      expect(cart.taxAmount, 5);
      expect(cart.serviceChargeAmount, 10);
      expect(cart.grandTotal, 115);
    });

    test('removes item when quantity set to 0', () {
      var cart = CartCalculator.addItem(
        base,
        menuItemId: 'm1',
        name: 'Item',
        unitPrice: 10,
      );
      cart = CartCalculator.updateQuantity(cart, 'm1', 0);
      expect(cart.isEmpty, isTrue);
    });
  });
}
