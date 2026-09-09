import '../domain/enums.dart';

abstract final class EnumParsers {
  static OrderStatus orderStatus(Object? raw) {
    final value = _normalize(raw);
    return switch (value) {
      'pending' => OrderStatus.pending,
      'accepted' => OrderStatus.accepted,
      'preparing' => OrderStatus.preparing,
      'ready' => OrderStatus.ready,
      'served' => OrderStatus.served,
      'completed' => OrderStatus.completed,
      'cancelled' || 'canceled' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
  }

  static PaymentStatus paymentStatus(Object? raw) {
    final value = _normalize(raw);
    return switch (value) {
      'unpaid' => PaymentStatus.unpaid,
      'payment_pending' || 'paymentpending' => PaymentStatus.paymentPending,
      'paid' => PaymentStatus.paid,
      _ => PaymentStatus.unpaid,
    };
  }

  static DiningSessionStatus diningSessionStatus(Object? raw) {
    final value = _normalize(raw);
    return switch (value) {
      'closed' => DiningSessionStatus.closed,
      _ => DiningSessionStatus.open,
    };
  }

  static StaffRole staffRole(Object? raw) {
    final value = _normalize(raw);
    return switch (value) {
      'admin' => StaffRole.admin,
      'manager' => StaffRole.manager,
      'waiter' => StaffRole.waiter,
      'kitchen' => StaffRole.kitchen,
      _ => StaffRole.waiter,
    };
  }

  static MenuItemDiet diet(Object? raw) {
    final value = _normalize(raw);
    return switch (value) {
      'veg' || 'vegetarian' => MenuItemDiet.veg,
      'nonveg' || 'non_veg' || 'non-veg' => MenuItemDiet.nonVeg,
      'egg' => MenuItemDiet.egg,
      'vegan' => MenuItemDiet.vegan,
      _ => MenuItemDiet.unknown,
    };
  }

  /// Maps Laravel [TableStatusDeriver] strings onto app display statuses.
  static TableDisplayStatus tableDisplayStatus(Object? raw) {
    final value = _normalize(raw);
    return switch (value) {
      'available' => TableDisplayStatus.available,
      'occupied' => TableDisplayStatus.occupied,
      'pending_orders' ||
      'accepted' ||
      'order_placed' ||
      'orderplaced' =>
        TableDisplayStatus.orderPlaced,
      'preparing' => TableDisplayStatus.preparing,
      'ready' => TableDisplayStatus.ready,
      'served' ||
      'awaiting_payment' ||
      'payment_pending' ||
      'paymentpending' =>
        TableDisplayStatus.paymentPending,
      'paid' => TableDisplayStatus.paid,
      'completed' => TableDisplayStatus.completed,
      _ => TableDisplayStatus.available,
    };
  }

  static String _normalize(Object? raw) {
    if (raw == null) return '';
    return raw
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }
}
