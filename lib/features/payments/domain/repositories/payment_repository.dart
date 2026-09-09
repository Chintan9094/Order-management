import '../../../customer_session/domain/entities/dining_session.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<Payment> markPaid(String paymentId);

  Future<DiningSession> closeSession(String sessionId);
}
