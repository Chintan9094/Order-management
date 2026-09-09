import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../cart/domain/cart_calculator.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../../customer_session/presentation/providers/customer_session_providers.dart';
import '../../../menu/domain/entities/menu.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/repositories/order_repository.dart';

final menuCatalogProvider =
    FutureProvider.autoDispose<MenuCatalog>((ref) async {
  final restaurantId = ref.watch(
    activeCustomerSessionProvider.select((s) => s?.restaurantId),
  );
  if (restaurantId == null) {
    throw StateError('Join a table before browsing the menu.');
  }
  return ref.read(menuRepositoryProvider).getMenu(restaurantId);
});

class CartController extends StateNotifier<Cart> {
  CartController({
    required String sessionId,
    double taxRate = 0,
    double service = 0,
  }) : super(
          Cart(
            sessionId: sessionId,
            taxRate: taxRate,
            serviceChargeRate: service,
          ),
        );

  void addItem(MenuItem item, {int quantity = 1}) {
    state = CartCalculator.addItem(
      state,
      menuItemId: item.id,
      name: item.name,
      unitPrice: item.price,
      quantity: quantity,
    );
  }

  void setQuantity(String menuItemId, int quantity) {
    state = CartCalculator.updateQuantity(state, menuItemId, quantity);
  }

  void removeItem(String menuItemId) {
    state = CartCalculator.removeItem(state, menuItemId);
  }

  void clear() {
    state = CartCalculator.clear(state);
  }
}

final cartControllerProvider =
    StateNotifierProvider.autoDispose<CartController, Cart>((ref) {
  final sessionMeta = ref.watch(
    activeCustomerSessionProvider.select(
      (s) => s == null
          ? null
          : (
              s.sessionId,
              s.taxRate,
              s.serviceChargeRate,
            ),
    ),
  );
  return CartController(
    sessionId: sessionMeta?.$1 ?? 'none',
    taxRate: sessionMeta?.$2 ?? 0,
    service: sessionMeta?.$3 ?? 0,
  );
});

final placeOrderControllerProvider =
    StateNotifierProvider.autoDispose<PlaceOrderController, AsyncValue<Order?>>(
        (ref) {
  return PlaceOrderController(ref);
});

class PlaceOrderController extends StateNotifier<AsyncValue<Order?>> {
  PlaceOrderController(this._ref) : super(const AsyncData(null));

  final Ref _ref;
  static const _uuid = Uuid();

  Future<Order?> submit({String? orderNote}) async {
    final session = _ref.read(activeCustomerSessionProvider);
    final cart = _ref.read(cartControllerProvider);
    if (session == null) {
      state = AsyncError(
        StateError('No active table session'),
        StackTrace.current,
      );
      return null;
    }
    if (cart.isEmpty) {
      state = AsyncError(
        StateError('Your cart is empty'),
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncLoading();
    try {
      final order = await _ref.read(orderRepositoryProvider).placeOrder(
            sessionId: session.sessionId,
            items: cart.lines
                .map(
                  (line) => PlaceOrderItemRequest(
                    menuItemId: line.menuItemId,
                    quantity: line.quantity,
                    note: line.note,
                  ),
                )
                .toList(),
            orderNote: orderNote,
            idempotencyKey: _uuid.v4(),
          );
      _ref.read(cartControllerProvider.notifier).clear();
      state = AsyncData(order);
      return order;
    } catch (e, st) {
      state = AsyncError(ErrorMapper.userMessage(e), st);
      return null;
    }
  }
}
