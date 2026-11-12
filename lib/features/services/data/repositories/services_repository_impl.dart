import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/service_entities.dart';
import '../../domain/repositories/services_repository.dart';
import '../datasources/services_data_sources.dart';

final class ServicesRepositoryImpl implements ServicesRepository {
  const ServicesRepositoryImpl(this._remote);
  final ServicesRemoteDataSource _remote;

  @override
  Future<Result<ServicesData>> getServices() => ErrorMapper.guard(_remote.services);

  @override
  Future<Result<String>> requestRide(String vehicleTypeId) =>
      ErrorMapper.guard(() => _remote.requestRide(vehicleTypeId));
}
