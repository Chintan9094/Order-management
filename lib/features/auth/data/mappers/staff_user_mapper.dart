import '../../../../core/network/json_helpers.dart';
import '../../../shared/data/enum_parsers.dart';
import '../../../shared/domain/staff_permissions.dart';
import '../../domain/entities/staff_user.dart';

abstract final class StaffUserMapper {
  static StaffUser fromJson(Map<String, dynamic> json) {
    final role = EnumParsers.staffRole(json['role']);
    return StaffUser(
      id: JsonHelpers.id(json['id']),
      restaurantId: JsonHelpers.id(
        JsonHelpers.pick(json, ['restaurantId', 'restaurant_id']),
      ),
      displayName: JsonHelpers.asString(json['name']) ?? '',
      email: JsonHelpers.asString(json['email']),
      role: role,
      permissions: StaffPermissions.defaultsFor(role),
      isActive: JsonHelpers.asBool(
        JsonHelpers.pick(json, ['isActive', 'is_active']),
        true,
      ),
    );
  }
}
