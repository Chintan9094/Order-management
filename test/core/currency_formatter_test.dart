import 'package:flutter_test/flutter_test.dart';
import 'package:order_management/core/utils/currency_formatter.dart';

void main() {
  test('formats whole INR without paise', () {
    expect(CurrencyFormatter.format(850), contains('850'));
    expect(CurrencyFormatter.format(850), startsWith('₹'));
  });
}
