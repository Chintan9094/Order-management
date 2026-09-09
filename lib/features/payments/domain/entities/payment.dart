import 'package:equatable/equatable.dart';

import '../../../shared/domain/enums.dart';

class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.sessionId,
    required this.status,
    required this.amountDue,
    this.amountPaid,
    this.paidAt,
    this.markedByStaffId,
  });

  final String id;
  final String sessionId;
  final PaymentStatus status;
  final double amountDue;
  final double? amountPaid;
  final DateTime? paidAt;
  final String? markedByStaffId;

  bool get isPaid => status == PaymentStatus.paid;

  @override
  List<Object?> get props => [
        id,
        sessionId,
        status,
        amountDue,
        amountPaid,
        paidAt,
        markedByStaffId,
      ];
}
