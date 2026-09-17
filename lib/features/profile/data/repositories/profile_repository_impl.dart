import '../../data/driver_profile_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl({ProfileRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ProfileRemoteDataSourceImpl();

  @override
  Future<DriverProfileModel> getProfile() async {
    final responseData = await _remoteDataSource.getProfile();
    final profileJson = responseData['data'] as Map<String, dynamic>;
    return DriverProfileModel.fromJson(profileJson);
  }

  @override
  Future<DriverProfileModel> updateDutyStatus(bool isOnline) async {
    final targetStatus = isOnline ? 'online' : 'offline';
    final responseData = await _remoteDataSource.updateDutyStatus(targetStatus);
    final data = responseData['data'] as Map<String, dynamic>?;

    return DriverProfileModel(
      userId: data?['user_id'] ?? 0,
      name: '',
      phone: '',
      isOnline: isOnline,
      operationalStatus: targetStatus,
      statusLabel: isOnline ? 'متصل ومتاح' : 'غير متصل',
    );
  }
}
