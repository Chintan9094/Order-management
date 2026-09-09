import 'dart:async';

import '../constants/app_constants.dart';
import 'order_event_source.dart';

/// Near-real-time fallback until WebSocket/SSE/Supabase is wired.
class PollingOrderEventSource implements OrderEventSource {
  PollingOrderEventSource({
    Duration staffInterval = AppConstants.staffOrdersPollInterval,
    Duration customerInterval = AppConstants.customerSessionPollInterval,
  })  : _staffInterval = staffInterval,
        _customerInterval = customerInterval;

  final Duration _staffInterval;
  final Duration _customerInterval;
  final _sessionControllers =
      <String, StreamController<SessionRealtimeEvent>>{};
  final _staffControllers =
      <String, StreamController<StaffOrdersRealtimeEvent>>{};
  final _timers = <String, Timer>{};
  final _listenerCounts = <String, int>{};

  @override
  Stream<SessionRealtimeEvent> watchSession(String sessionId) {
    final key = 'session:$sessionId';
    _listenerCounts[key] = (_listenerCounts[key] ?? 0) + 1;

    final existing = _sessionControllers[sessionId];
    if (existing != null) return existing.stream;

    late final StreamController<SessionRealtimeEvent> controller;
    controller = StreamController<SessionRealtimeEvent>.broadcast(
      onCancel: () {
        final remaining = (_listenerCounts[key] ?? 1) - 1;
        if (remaining <= 0) {
          _listenerCounts.remove(key);
          _timers.remove(key)?.cancel();
          _sessionControllers.remove(sessionId);
          if (!controller.isClosed) controller.close();
        } else {
          _listenerCounts[key] = remaining;
        }
      },
    );
    _sessionControllers[sessionId] = controller;

    _timers[key] = Timer.periodic(_customerInterval, (_) {
      if (!controller.isClosed) {
        controller.add(SessionUpdatedEvent(sessionId));
      }
    });

    return controller.stream;
  }

  @override
  Stream<StaffOrdersRealtimeEvent> watchRestaurantOrders(String restaurantId) {
    final key = 'staff:$restaurantId';
    _listenerCounts[key] = (_listenerCounts[key] ?? 0) + 1;

    final existing = _staffControllers[restaurantId];
    if (existing != null) return existing.stream;

    late final StreamController<StaffOrdersRealtimeEvent> controller;
    controller = StreamController<StaffOrdersRealtimeEvent>.broadcast(
      onCancel: () {
        final remaining = (_listenerCounts[key] ?? 1) - 1;
        if (remaining <= 0) {
          _listenerCounts.remove(key);
          _timers.remove(key)?.cancel();
          _staffControllers.remove(restaurantId);
          if (!controller.isClosed) controller.close();
        } else {
          _listenerCounts[key] = remaining;
        }
      },
    );
    _staffControllers[restaurantId] = controller;

    _timers[key] = Timer.periodic(_staffInterval, (_) {
      if (!controller.isClosed) {
        controller.add(StaffOrdersChangedEvent(restaurantId));
      }
    });

    return controller.stream;
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _listenerCounts.clear();
    for (final c in _sessionControllers.values) {
      c.close();
    }
    _sessionControllers.clear();
    for (final c in _staffControllers.values) {
      c.close();
    }
    _staffControllers.clear();
  }
}
