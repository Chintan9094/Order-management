import 'package:equatable/equatable.dart';

class CartLine extends Equatable {
  const CartLine({
    required this.menuItemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.note,
  });

  final String menuItemId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? note;

  double get lineTotal => unitPrice * quantity;

  CartLine copyWith({
    String? menuItemId,
    String? name,
    double? unitPrice,
    int? quantity,
    String? note,
  }) {
    return CartLine(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [menuItemId, name, unitPrice, quantity, note];
}

class Cart extends Equatable {
  const Cart({
    required this.sessionId,
    this.lines = const [],
    this.taxRate = 0,
    this.serviceChargeRate = 0,
  });

  final String sessionId;
  final List<CartLine> lines;
  final double taxRate;
  final double serviceChargeRate;

  double get subtotal =>
      lines.fold(0, (sum, line) => sum + line.lineTotal);

  double get taxAmount => subtotal * taxRate;
  double get serviceChargeAmount => subtotal * serviceChargeRate;
  double get grandTotal => subtotal + taxAmount + serviceChargeAmount;

  bool get isEmpty => lines.isEmpty;

  Cart copyWith({
    String? sessionId,
    List<CartLine>? lines,
    double? taxRate,
    double? serviceChargeRate,
  }) {
    return Cart(
      sessionId: sessionId ?? this.sessionId,
      lines: lines ?? this.lines,
      taxRate: taxRate ?? this.taxRate,
      serviceChargeRate: serviceChargeRate ?? this.serviceChargeRate,
    );
  }

  @override
  List<Object?> get props => [sessionId, lines, taxRate, serviceChargeRate];
}
