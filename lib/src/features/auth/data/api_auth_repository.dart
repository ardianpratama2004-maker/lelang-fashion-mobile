import '../../../data/api/api_client.dart';
import '../../../data/models/auth_result.dart';
import '../domain/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  const ApiAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<AuthResult> register(
    String name,
    String email,
    String password,
    String confirm,
  ) {
    return _api.register(name, email, password, confirm);
  }

  @override
  Future<AuthResult> login(String email, String password) {
    return _api.login(email, password);
  }
}
