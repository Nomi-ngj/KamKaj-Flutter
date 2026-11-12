import '../../../../core/errors/result.dart';
import '../entities/service_entities.dart';
import '../repositories/services_repository.dart';

final class GetServices {
  const GetServices(this._repository);
  final ServicesRepository _repository;

  Future<Result<ServicesData>> call() => _repository.getServices();
}

final class RequestRide {
  const RequestRide(this._repository);
  final ServicesRepository _repository;

  Future<Result<String>> call(VehicleType vehicle) => _repository.requestRide(vehicle.id);
}
