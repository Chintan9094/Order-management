import '../../shared/domain/enums.dart';

/// Controlled order status transitions.
/// Staff UI path: Accept → Prepare → Serve → Completed.
abstract final class OrderStatusMachine {
  static const Map<OrderStatus, Set<OrderStatus>> _transitions = {
    OrderStatus.pending: {OrderStatus.accepted, OrderStatus.cancelled},
    OrderStatus.accepted: {OrderStatus.preparing, OrderStatus.cancelled},
    OrderStatus.preparing: {OrderStatus.served, OrderStatus.ready},
    OrderStatus.ready: {OrderStatus.served},
    OrderStatus.served: {OrderStatus.completed},
    OrderStatus.completed: {},
    OrderStatus.cancelled: {},
  };

  static bool canTransition(OrderStatus from, OrderStatus to) {
    return _transitions[from]?.contains(to) ?? false;
  }

  /// Cancel rules: anyone with order rights until accepted;
  /// managerOverride allows cancel while accepted (before preparing).
  static bool canCancel({
    required OrderStatus current,
    required bool isManagerOrAbove,
  }) {
    if (current == OrderStatus.pending) return true;
    if (current == OrderStatus.accepted && isManagerOrAbove) return true;
    return false;
  }

  static void assertTransition(OrderStatus from, OrderStatus to) {
    if (!canTransition(from, to)) {
      throw StateError('Invalid order status transition: $from → $to');
    }
  }
}
