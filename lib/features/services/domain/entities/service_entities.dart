import 'package:equatable/equatable.dart';

/// A service card on the Services screen ("Express Ride", "Delivery Package").
final class ServiceOffering extends Equatable {
  const ServiceOffering({required this.id, required this.name, required this.imageKey});

  final String id;
  final String name;

  /// Key the UI maps to a bundled illustration.
  final String imageKey;

  @override
  List<Object?> get props => [id, name, imageKey];
}

/// "Book A Ride Now" vehicle option.
final class VehicleType extends Equatable {
  const VehicleType({
    required this.id,
    required this.name,
    required this.imageKey,
    required this.capacity,
  });

  final String id;
  final String name;
  final String imageKey;

  /// Passenger seats or load description shown on the confirm sheet.
  final String capacity;

  @override
  List<Object?> get props => [id, name, imageKey, capacity];
}

final class ServicesData extends Equatable {
  const ServicesData({required this.services, required this.vehicles});

  final List<ServiceOffering> services;
  final List<VehicleType> vehicles;

  @override
  List<Object?> get props => [services, vehicles];
}
