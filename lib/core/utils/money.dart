import 'package:equatable/equatable.dart';

/// Money stored in minor units (paisa) to avoid floating-point errors.
final class Money extends Equatable implements Comparable<Money> {
  const Money(this.minorUnits, {this.currency = 'PKR'});

  const Money.zero({this.currency = 'PKR'}) : minorUnits = 0;

  factory Money.fromMajor(num amount, {String currency = 'PKR'}) =>
      Money((amount * 100).round(), currency: currency);

  final int minorUnits;
  final String currency;

  double get major => minorUnits / 100;
  bool get isZero => minorUnits == 0;

  Money operator +(Money other) => Money(minorUnits + other.minorUnits, currency: currency);
  Money operator -(Money other) => Money(minorUnits - other.minorUnits, currency: currency);
  Money operator *(int factor) => Money(minorUnits * factor, currency: currency);

  /// "PKR 650", "PKR 120.50".
  String format() {
    final whole = minorUnits ~/ 100;
    final fraction = (minorUnits % 100).abs();
    final wholeText = _group(whole.abs());
    final sign = minorUnits < 0 ? '-' : '';
    final fractionText = fraction == 0 ? '' : '.${fraction.toString().padLeft(2, '0')}';
    return '$currency $sign$wholeText$fractionText';
  }

  /// "PKR 0.00" style, always two decimals.
  String formatFixed() {
    final whole = minorUnits ~/ 100;
    final fraction = (minorUnits % 100).abs().toString().padLeft(2, '0');
    return '$currency ${_group(whole)}.$fraction';
  }

  static String _group(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  int compareTo(Money other) => minorUnits.compareTo(other.minorUnits);

  @override
  List<Object?> get props => [minorUnits, currency];

  @override
  String toString() => format();
}
