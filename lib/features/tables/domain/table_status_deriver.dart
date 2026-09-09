import '../../orders/domain/entities/order.dart';
import '../../payments/domain/entities/payment.dart';
import '../../shared/domain/enums.dart';
import '../../customer_session/domain/entities/dining_session.dart';

/// Derives table UI status from session + orders + payment (source of truth).
abstract final class TableStatusDeriver {
  static TableDisplayStatus derive({
    DiningSession? session,
    List<Order> orders = const [],
    Payment? payment,
  }) {
    if (session == null || session.status == DiningSessionStatus.closed) {
      return TableDisplayStatus.available;
    }

    if (payment?.status == PaymentStatus.paid) {
      return TableDisplayStatus.paid;
    }

    final activeOrders =
        orders.where((o) => o.status != OrderStatus.cancelled).toList();

    if (activeOrders.isEmpty) {
      return TableDisplayStatus.occupied;
    }

    if (payment?.status == PaymentStatus.paymentPending ||
        _allFoodDone(activeOrders)) {
      if (_allFoodDone(activeOrders) &&
          (payment == null || payment.status != PaymentStatus.paid)) {
        return TableDisplayStatus.paymentPending;
      }
    }

    if (activeOrders.any((o) => o.status == OrderStatus.ready)) {
      return TableDisplayStatus.ready;
    }
    if (activeOrders.any((o) => o.status == OrderStatus.preparing)) {
      return TableDisplayStatus.preparing;
    }
    if (activeOrders.any(
      (o) =>
          o.status == OrderStatus.pending || o.status == OrderStatus.accepted,
    )) {
      return TableDisplayStatus.orderPlaced;
    }
    if (activeOrders.any((o) => o.status == OrderStatus.served) ||
        activeOrders.every((o) => o.status == OrderStatus.completed)) {
      return TableDisplayStatus.paymentPending;
    }

    return TableDisplayStatus.occupied;
  }

  static bool _allFoodDone(List<Order> orders) {
    if (orders.isEmpty) return false;
    return orders.every(
      (o) =>
          o.status == OrderStatus.served ||
          o.status == OrderStatus.completed,
    );
  }

  static bool canBecomeAvailable({
    DiningSession? session,
    Payment? payment,
    List<Order> orders = const [],
  }) {
    if (session == null || session.status == DiningSessionStatus.closed) {
      return true;
    }
    final unpaidActive = orders.any((o) => !o.isTerminal) ||
        (payment != null &&
            payment.status != PaymentStatus.paid &&
            payment.amountDue > 0);
    return !unpaidActive && payment?.status == PaymentStatus.paid;
  }
}
