import 'package:equatable/equatable.dart';

import '../../../shared/domain/enums.dart';

class StaffUser extends Equatable {
  const StaffUser({
    required this.id,
    required this.restaurantId,
    required this.displayName,
    required this.role,
    this.email,
    this.permissions = const [],
    this.isActive = true,
  });

  final String id;
  final String restaurantId;
  final String displayName;
  final String? email;
  final StaffRole role;
  final List<String> permissions;
  final bool isActive;

  bool hasPermission(String permission) {
    if (role == StaffRole.admin) return true;
    return permissions.contains(permission);
  }

  @override
  List<Object?> get props =>
      [id, restaurantId, displayName, email, role, permissions, isActive];
}

class StaffAuthSession extends Equatable {
  const StaffAuthSession({
    required this.accessToken,
    required this.user,
    this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  /// Sanctum issues a single token; refresh is unused.
  final String? refreshToken;
  final StaffUser user;
  final DateTime? expiresAt;

  @override
  List<Object?> get props => [accessToken, refreshToken, user, expiresAt];
}
