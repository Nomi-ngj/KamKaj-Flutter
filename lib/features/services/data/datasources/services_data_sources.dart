import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_reader.dart';
import '../../domain/entities/service_entities.dart';

abstract interface class ServicesRemoteDataSource {
  Future<ServicesData> services();
  Future<String> requestRide(String vehicleTypeId);
}

final class ServicesRemoteDataSourceImpl implements ServicesRemoteDataSource {
  const ServicesRemoteDataSourceImpl(this._client);
  final DioClient _client;

  @override
  Future<ServicesData> services() async {
    final results = await Future.wait([
      _client.getList(ApiEndpoints.services),
      _client.getList(ApiEndpoints.vehicleTypes),
    ]);
    return ServicesData(
      services: results[0]
          .map(
            (j) => ServiceOffering(
              id: j.readString('id'),
              name: j.readString('name'),
              imageKey: j.readStringOrNull('image') ?? '',
            ),
          )
          .toList(),
      vehicles: results[1]
          .map(
            (j) => VehicleType(
              id: j.readString('id'),
              name: j.readString('name'),
              imageKey: j.readStringOrNull('image') ?? '',
              capacity: j.readStringOrNull('capacity') ?? '',
            ),
          )
          .toList(),
    );
  }

  @override
  Future<String> requestRide(String vehicleTypeId) async =>
      (await _client.post(ApiEndpoints.rides, body: {'vehicleTypeId': vehicleTypeId})).readString('id');
}

final class ServicesMockDataSource implements ServicesRemoteDataSource {
  const ServicesMockDataSource({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  @override
  Future<ServicesData> services() async {
    await Future<void>.delayed(latency);
    return const ServicesData(
      services: [
        ServiceOffering(id: 'express_ride', name: 'Express Ride', imageKey: 'express_ride'),
        ServiceOffering(id: 'delivery_package', name: 'Delivery Package', imageKey: 'delivery_package'),
        ServiceOffering(id: 'moving', name: 'Home Moving', imageKey: 'express_ride'),
      ],
      vehicles: [
        VehicleType(id: 'sedan', name: 'Sedan / Car', imageKey: 'sedan', capacity: 'Up to 4 riders'),
        VehicleType(id: 'van', name: 'Van / Shuttle', imageKey: 'van', capacity: 'Up to 8 riders'),
        VehicleType(id: 'truck', name: 'Utility Truck', imageKey: 'truck', capacity: 'Up to 1 tonne'),
      ],
    );
  }

  @override
  Future<String> requestRide(String vehicleTypeId) async {
    await Future<void>.delayed(latency);
    return 'ride_${DateTime.now().millisecondsSinceEpoch}';
  }
}
