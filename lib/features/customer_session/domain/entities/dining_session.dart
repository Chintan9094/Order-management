import 'package:equatable/equatable.dart';

import '../../../shared/domain/enums.dart';

class DiningSession extends Equatable {
  const DiningSession({
    required this.id,
    required this.restaurantId,
    required this.tableId,
    required this.status,
    required this.startedAt,
    this.closedAt,
    this.allowsNewOrders = true,
  });

  final String id;
  final String restaurantId;
  final String tableId;
  final DiningSessionStatus status;
  final DateTime startedAt;
  final DateTime? closedAt;
  final bool allowsNewOrders;

  bool get isOpen => status == DiningSessionStatus.open;

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        tableId,
        status,
        startedAt,
        closedAt,
        allowsNewOrders,
      ];
}
