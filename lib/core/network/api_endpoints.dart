/// API path constants. Base URL comes from [AppConfig].
abstract final class ApiEndpoints {
  // Public / customer
  static const String resolveTable = '/tables/resolve';
  static String restaurantMenu(String restaurantId) =>
      '/restaurants/$restaurantId/menu';
  static String session(String sessionId) => '/sessions/$sessionId';
  static String sessionOrders(String sessionId) =>
      '/sessions/$sessionId/orders';

  // Staff auth
  static const String staffLogin = '/auth/login';
  static const String staffLogout = '/auth/logout';
  static const String staffMe = '/auth/me';

  // Staff ops
  static const String dashboard = '/dashboard';
  static const String orders = '/orders';
  static String orderStatus(String orderId) => '/orders/$orderId/status';
  static const String tables = '/tables';
  static String table(String tableId) => '/tables/$tableId';
  static String tableQr(String tableId) => '/tables/$tableId/qr';
  static const String categories = '/categories';
  static String category(String categoryId) => '/categories/$categoryId';
  static const String menuItems = '/menu-items';
  static String menuItem(String itemId) => '/menu-items/$itemId';
  static String markPaid(String paymentId) =>
      '/payments/$paymentId/mark-paid';
  static String closeSession(String sessionId) =>
      '/sessions/$sessionId/close';
}
