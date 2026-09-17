import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({AuthRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSourceImpl();

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _remoteDataSource.login(email, password);

    final user = data['user'] as Map<String, dynamic>?;
    final role = user?['role'];

    if (role != null && role != 'driver') {
      throw const ForbiddenException(
        message: 'هذا الحساب ليس لديه صلاحية كابتن توصيل (Driver). يرجى استخدام حساب كابتن معتمد.',
      );
    }

    final token = data['token'] as String?;
    if (token != null && token.isNotEmpty) {
      DioClient.setToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    }

    return data;
  }

  @override
  Future<void> logout() async {
    DioClient.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  @override
  Future<String?> getToken() async {
    final cached = DioClient.getToken();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    final prefs = await SharedPreferences.getInstance();
    final diskToken = prefs.getString('auth_token');
    if (diskToken != null && diskToken.isNotEmpty) {
      DioClient.setToken(diskToken);
    }
    return diskToken;
  }

  @override
  Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
