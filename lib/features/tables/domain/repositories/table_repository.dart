import '../entities/restaurant_table.dart';

class TableQrInfo {
  const TableQrInfo({
    required this.tableId,
    required this.label,
    required this.publicToken,
    required this.qrPayload,
  });

  final String tableId;
  final String label;
  final String publicToken;
  /// Deep-link string suitable for [QrImageView], e.g. `restaurant-app://t/table-1`.
  final String qrPayload;
}

abstract class TableRepository {
  Future<List<RestaurantTable>> listTables();
  Future<RestaurantTable> createTable({
    required String label,
    int? capacity,
  });
  Future<RestaurantTable> updateTable(RestaurantTable table);
  Future<void> deactivateTable(String tableId);
  Future<TableQrInfo> getTableQr(String tableId);
}
