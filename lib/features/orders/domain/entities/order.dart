import 'package:equatable/equatable.dart';

import '../../../shared/domain/enums.dart';

class OrderItem extends Equatable {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.nameSnapshot,
    required this.unitPriceSnapshot,
    required this.quantity,
    required this.lineTotal,
    this.menuItemId,
    this.note,
  });

  final String id;
  final String orderId;
  final String? menuItemId;
  final String nameSnapshot;
  final double unitPriceSnapshot;
  final int quantity;
  final double lineTotal;
  final String? note;

  @override
  List<Object?> get props => [
        id,
        orderId,
        menuItemId,
        nameSnapshot,
        unitPriceSnapshot,
        quantity,
        lineTotal,
        note,
      ];
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.sessionId,
    required this.restaurantId,
    required this.tableId,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.grandTotal,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  final String id;
  final String sessionId;
  final String restaurantId;
  final String tableId;
  final OrderStatus status;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double serviceCharge;
  final double grandTotal;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTerminal =>
      status == OrderStatus.completed || status == OrderStatus.cancelled;

  @override
  List<Object?> get props => [
        id,
        sessionId,
        restaurantId,
        tableId,
        status,
        items,
        subtotal,
        tax,
        serviceCharge,
        grandTotal,
        notes,
        createdAt,
        updatedAt,
      ];
}
