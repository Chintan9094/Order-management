import '../entities/staff_user.dart';

abstract class AuthRepository {
  Future<StaffAuthSession> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<StaffUser?> currentUser();
}
