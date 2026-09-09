/// Abstract realtime source — swap polling for WebSocket/SSE later without UI rewrites.
abstract class OrderEventSource {
  Stream<SessionRealtimeEvent> watchSession(String sessionId);
  Stream<StaffOrdersRealtimeEvent> watchRestaurantOrders(String restaurantId);
  void dispose();
}

sealed class SessionRealtimeEvent {
  const SessionRealtimeEvent();
}

class SessionUpdatedEvent extends SessionRealtimeEvent {
  const SessionUpdatedEvent(this.sessionId);
  final String sessionId;
}

class SessionOrderUpdatedEvent extends SessionRealtimeEvent {
  const SessionOrderUpdatedEvent({
    required this.sessionId,
    required this.orderId,
  });
  final String sessionId;
  final String orderId;
}

class SessionPaymentUpdatedEvent extends SessionRealtimeEvent {
  const SessionPaymentUpdatedEvent(this.sessionId);
  final String sessionId;
}

sealed class StaffOrdersRealtimeEvent {
  const StaffOrdersRealtimeEvent();
}

class StaffOrdersChangedEvent extends StaffOrdersRealtimeEvent {
  const StaffOrdersChangedEvent(this.restaurantId);
  final String restaurantId;
}
