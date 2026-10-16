import '../../../data/models/auth_result.dart';

abstract class AuthRepository {
  Future<AuthResult> register(
    String name,
    String email,
    String password,
    String confirm,
  );

  Future<AuthResult> login(String email, String password);
}
