import 'package:equatable/equatable.dart';

enum AddressType {
  home('Home'),
  work('Work'),
  other('Other');

  const AddressType(this.label);
  final String label;
}

final class Address extends Equatable {
  const Address({
    required this.id,
    required this.type,
    required this.label,
    required this.street,
    required this.city,
    this.apartment,
    this.driverNotes,
    this.isDefault = false,
  });

  final String id;
  final AddressType type;

  /// e.g. "My Home", "My Office Work Address".
  final String label;
  final String street;

  /// e.g. "Springfield, IL 62704".
  final String city;
  final String? apartment;
  final String? driverNotes;
  final bool isDefault;

  String get streetLine =>
      apartment == null || apartment!.isEmpty ? street : '$street, $apartment';

  Address copyWith({bool? isDefault}) => Address(
        id: id,
        type: type,
        label: label,
        street: street,
        city: city,
        apartment: apartment,
        driverNotes: driverNotes,
        isDefault: isDefault ?? this.isDefault,
      );

  @override
  List<Object?> get props => [id, type, label, street, city, apartment, driverNotes, isDefault];
}

/// Input for creating / editing an address.
final class AddressDraft extends Equatable {
  const AddressDraft({
    required this.type,
    required this.street,
    this.city = '',
    this.apartment,
    this.driverNotes,
  });

  final AddressType type;
  final String street;
  final String city;
  final String? apartment;
  final String? driverNotes;

  @override
  List<Object?> get props => [type, street, city, apartment, driverNotes];
}
