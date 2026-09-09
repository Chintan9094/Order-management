import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/network/auth_token_store.dart';
import '../../domain/repositories/customer_session_repository.dart';

@immutable
class ActiveCustomerSession {
  const ActiveCustomerSession({
    required this.sessionId,
    required this.restaurantId,
    required this.restaurantName,
    required this.tableId,
    required this.tableLabel,
    required this.taxRate,
    required this.serviceChargeRate,
    this.paymentId,
    this.currencyCode = 'INR',
  });

  final String sessionId;
  final String restaurantId;
  final String restaurantName;
  final String tableId;
  final String tableLabel;
  final double taxRate;
  final double serviceChargeRate;
  final String? paymentId;
  final String currencyCode;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'tableId': tableId,
        'tableLabel': tableLabel,
        'taxRate': taxRate,
        'serviceChargeRate': serviceChargeRate,
        'paymentId': paymentId,
        'currencyCode': currencyCode,
      };

  factory ActiveCustomerSession.fromJson(Map<String, dynamic> json) {
    return ActiveCustomerSession(
      sessionId: json['sessionId']?.toString() ?? '',
      restaurantId: json['restaurantId']?.toString() ?? '',
      restaurantName: json['restaurantName']?.toString() ?? '',
      tableId: json['tableId']?.toString() ?? '',
      tableLabel: json['tableLabel']?.toString() ?? '',
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0,
      serviceChargeRate: (json['serviceChargeRate'] as num?)?.toDouble() ?? 0,
      paymentId: json['paymentId']?.toString(),
      currencyCode: json['currencyCode']?.toString() ?? 'INR',
    );
  }

  ActiveCustomerSession copyWith({String? paymentId}) {
    return ActiveCustomerSession(
      sessionId: sessionId,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      tableId: tableId,
      tableLabel: tableLabel,
      taxRate: taxRate,
      serviceChargeRate: serviceChargeRate,
      paymentId: paymentId ?? this.paymentId,
      currencyCode: currencyCode,
    );
  }
}

class CustomerSessionController
    extends StateNotifier<AsyncValue<ActiveCustomerSession?>> {
  CustomerSessionController(this._ref) : super(const AsyncData(null)) {
    _restore();
  }

  final Ref _ref;
  static const _prefsKey = 'active_customer_session';

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      final token =
          await _ref.read(authTokenStoreProvider).readCustomerSessionToken();
      if (raw == null || token == null || token.isEmpty) {
        state = const AsyncData(null);
        return;
      }
      final map = jsonDecode(raw) as Map<String, dynamic>;
      state = AsyncData(ActiveCustomerSession.fromJson(map));
    } catch (_) {
      state = const AsyncData(null);
    }
  }

  Future<void> _persist(ActiveCustomerSession? session) async {
    final prefs = await SharedPreferences.getInstance();
    if (session == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, jsonEncode(session.toJson()));
    }
  }

  Future<ActiveCustomerSession> resolveTable(String tablePublicToken) async {
    state = const AsyncLoading();
    try {
      final result = await _ref
          .read(customerSessionRepositoryProvider)
          .resolveTable(tablePublicToken: tablePublicToken);
      final active = ActiveCustomerSession(
        sessionId: result.session.id,
        restaurantId: result.restaurant.id,
        restaurantName: result.restaurant.name,
        tableId: result.table.id,
        tableLabel: result.table.label,
        taxRate: result.restaurant.taxRate,
        serviceChargeRate: result.restaurant.serviceChargeRate,
        paymentId: result.payment?.id,
        currencyCode: result.restaurant.currencyCode,
      );
      await _persist(active);
      state = AsyncData(active);
      return active;
    } catch (e, st) {
      state = AsyncError(e, st);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> clear() async {
    await _ref.read(authTokenStoreProvider).clearCustomerSessionToken();
    await _persist(null);
    state = const AsyncData(null);
  }

  Future<DiningSessionDetail> refreshSessionDetail() async {
    final current = state.valueOrNull;
    if (current == null) {
      throw StateError('No active customer session');
    }
    final detail = await _ref
        .read(customerSessionRepositoryProvider)
        .getSession(current.sessionId);

    final nextPaymentId = detail.payment?.id;
    if (nextPaymentId != null && nextPaymentId != current.paymentId) {
      final updated = current.copyWith(paymentId: nextPaymentId);
      await _persist(updated);
      state = AsyncData(updated);
    }
    return detail;
  }
}

final customerSessionControllerProvider = StateNotifierProvider<
    CustomerSessionController, AsyncValue<ActiveCustomerSession?>>((ref) {
  return CustomerSessionController(ref);
});

final activeCustomerSessionProvider = Provider<ActiveCustomerSession?>((ref) {
  return ref.watch(customerSessionControllerProvider).valueOrNull;
});
