import 'package:equatable/equatable.dart';

import '../../../shared/domain/enums.dart';

class RestaurantTable extends Equatable {
  const RestaurantTable({
    required this.id,
    required this.restaurantId,
    required this.label,
    required this.publicToken,
    this.capacity,
    this.isActive = true,
    this.displayStatus = TableDisplayStatus.available,
    this.openSessionId,
    this.openPaymentId,
    this.openPaymentStatus,
    this.openPaymentAmountDue,
  });

  final String id;
  final String restaurantId;
  final String label;
  final String publicToken;
  final int? capacity;
  final bool isActive;
  final TableDisplayStatus displayStatus;
  final String? openSessionId;
  final String? openPaymentId;
  final PaymentStatus? openPaymentStatus;
  final double? openPaymentAmountDue;

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        label,
        publicToken,
        capacity,
        isActive,
        displayStatus,
        openSessionId,
        openPaymentId,
        openPaymentStatus,
        openPaymentAmountDue,
      ];
}
