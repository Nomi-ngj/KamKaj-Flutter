import '../../../../core/errors/result.dart';
import '../entities/service_entities.dart';

abstract interface class ServicesRepository {
  Future<Result<ServicesData>> getServices();

  /// Requests a ride; returns the ride reference.
  Future<Result<String>> requestRide(String vehicleTypeId);
}
