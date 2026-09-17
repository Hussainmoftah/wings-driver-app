import '../../domain/repositories/location_repository.dart';
import '../datasources/location_remote_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource _remoteDataSource;

  LocationRepositoryImpl({LocationRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? LocationRemoteDataSourceImpl();

  @override
  Future<void> updateLocation(
    double latitude,
    double longitude, {
    double? heading,
    double? accuracy,
  }) async {
    await _remoteDataSource.updateLocation(
      latitude,
      longitude,
      heading: heading,
      accuracy: accuracy,
    );
  }
}
