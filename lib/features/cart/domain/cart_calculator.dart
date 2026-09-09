import 'entities/cart.dart';

/// Local cart mutations. Server recalculates authoritative totals on place-order.
abstract final class CartCalculator {
  static Cart addItem(
    Cart cart, {
    required String menuItemId,
    required String name,
    required double unitPrice,
    int quantity = 1,
    String? note,
  }) {
    if (quantity <= 0) return cart;
    final lines = [...cart.lines];
    final index = lines.indexWhere(
      (l) => l.menuItemId == menuItemId && l.note == note,
    );
    if (index >= 0) {
      final existing = lines[index];
      lines[index] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      lines.add(
        CartLine(
          menuItemId: menuItemId,
          name: name,
          unitPrice: unitPrice,
          quantity: quantity,
          note: note,
        ),
      );
    }
    return cart.copyWith(lines: lines);
  }

  static Cart updateQuantity(Cart cart, String menuItemId, int quantity) {
    if (quantity <= 0) {
      return removeItem(cart, menuItemId);
    }
    final lines = cart.lines.map((line) {
      if (line.menuItemId != menuItemId) return line;
      return line.copyWith(quantity: quantity);
    }).toList();
    return cart.copyWith(lines: lines);
  }

  static Cart removeItem(Cart cart, String menuItemId) {
    return cart.copyWith(
      lines: cart.lines.where((l) => l.menuItemId != menuItemId).toList(),
    );
  }

  static Cart clear(Cart cart) => cart.copyWith(lines: const []);
}
