import 'user_account.dart';

class AuthResult {
  const AuthResult({required this.user, required this.token});

  final UserAccount user;
  final String token;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      user: UserAccount.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}
