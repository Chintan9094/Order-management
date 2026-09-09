import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

abstract final class CurrencyFormatter {
  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  static final NumberFormat _inrWithPaise = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  /// Formats amounts in INR. Uses paise when not a whole rupee.
  static String format(num amount) {
    if (amount % 1 == 0) {
      return _inr.format(amount);
    }
    return _inrWithPaise.format(amount);
  }
}
