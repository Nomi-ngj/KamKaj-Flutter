import 'package:flutter_test/flutter_test.dart';
import 'package:kamkaj_pro/core/utils/money.dart';
import 'package:kamkaj_pro/features/checkout/domain/usecases/checkout_usecases.dart';

void main() {
  const calculate = CalculateCheckoutSummary();

  test('matches the Figma checkout: free delivery over the threshold', () {
    final summary = calculate(Money.fromMajor(1750));
    expect(summary.isFreeDelivery, isTrue);
    expect(summary.serviceFee, Money.fromMajor(150));
    expect(summary.total, Money.fromMajor(1900));
  });

  test('charges standard delivery below the threshold', () {
    final summary = calculate(Money.fromMajor(450));
    expect(summary.deliveryFee, Money.fromMajor(100));
    expect(summary.total, Money.fromMajor(700));
  });

  test('an empty basket costs nothing', () {
    final summary = calculate(const Money.zero());
    expect(summary.total, const Money.zero());
  });
}
