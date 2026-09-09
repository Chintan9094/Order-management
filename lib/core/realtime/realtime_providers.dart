import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_event_source.dart';
import 'polling_order_event_source.dart';

final orderEventSourceProvider = Provider<OrderEventSource>((ref) {
  final source = PollingOrderEventSource();
  ref.onDispose(source.dispose);
  return source;
});
