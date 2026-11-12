import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/core/utils/money.dart';

void main() {
  test('formats whole and fractional amounts', () {
    expect(Money.fromMajor(650).format(), 'PKR 650');
    expect(Money.fromMajor(1750).format(), 'PKR 1,750');
    expect(Money.fromMajor(120.5).format(), 'PKR 120.50');
    expect(const Money.zero().formatFixed(), 'PKR 0.00');
    expect(Money.fromMajor(1234567).format(), 'PKR 1,234,567');
  });

  test('arithmetic stays exact in minor units', () {
    final total = Money.fromMajor(0.1) + Money.fromMajor(0.2);
    expect(total, Money.fromMajor(0.3));
    expect(Money.fromMajor(450) * 2, Money.fromMajor(900));
    expect(Money.fromMajor(100) - Money.fromMajor(150), Money.fromMajor(-50));
  });

  test('compares by value', () {
    expect(Money.fromMajor(10).compareTo(Money.fromMajor(5)), greaterThan(0));
    expect(Money.fromMajor(5), equals(const Money(500)));
  });
}
