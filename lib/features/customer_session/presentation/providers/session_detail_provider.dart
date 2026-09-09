import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/customer_session_providers.dart';
import '../../domain/repositories/customer_session_repository.dart';

final sessionDetailProvider =
    FutureProvider.autoDispose<DiningSessionDetail>((ref) async {
  final sessionId = ref.watch(
    activeCustomerSessionProvider.select((s) => s?.sessionId),
  );
  if (sessionId == null) {
    throw StateError('No active customer session');
  }
  return ref
      .read(customerSessionControllerProvider.notifier)
      .refreshSessionDetail();
});
