import 'enums.dart';

abstract final class StaffPermissions {
  static const manageMenu = 'manage_menu';
  static const manageTables = 'manage_tables';
  static const manageOrders = 'manage_orders';
  static const updateKitchenStatus = 'update_kitchen_status';
  static const markPayment = 'mark_payment';
  static const viewReports = 'view_reports';
  static const manageStaff = 'manage_staff';

  static List<String> defaultsFor(StaffRole role) {
    return switch (role) {
      StaffRole.admin => const [
          manageMenu,
          manageTables,
          manageOrders,
          updateKitchenStatus,
          markPayment,
          viewReports,
          manageStaff,
        ],
      StaffRole.manager => const [
          manageMenu,
          manageTables,
          manageOrders,
          updateKitchenStatus,
          markPayment,
          viewReports,
        ],
      StaffRole.waiter => const [
          manageOrders,
          markPayment,
        ],
      StaffRole.kitchen => const [
          updateKitchenStatus,
        ],
    };
  }
}
