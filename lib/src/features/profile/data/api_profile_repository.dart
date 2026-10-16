import 'package:image_picker/image_picker.dart';

import '../../../data/api/api_client.dart';
import '../../../data/models/identity_verification.dart';
import '../../../data/models/user_account.dart';
import '../domain/profile_repository.dart';

class ApiProfileRepository implements ProfileRepository {
  const ApiProfileRepository(this._api);

  final ApiClient _api;

  @override
  Future<UserAccount> me() {
    return _api.me();
  }

  @override
  Future<UserAccount> resendWhatsappOtp() {
    return _api.resendWhatsappOtp();
  }

  @override
  Future<UserAccount> updateWhatsapp(String whatsapp) {
    return _api.updateWhatsapp(whatsapp);
  }

  @override
  Future<UserAccount> verifyWhatsappOtp(String code) {
    return _api.verifyWhatsappOtp(code);
  }

  @override
  Future<IdentityVerification?> identityVerification() {
    return _api.identityVerification();
  }

  @override
  Future<IdentityVerification> submitIdentityVerification({
    required String nik,
    required String name,
    required XFile ktp,
    required XFile selfie,
  }) {
    return _api.submitIdentityVerification(
      nik: nik,
      name: name,
      ktp: ktp,
      selfie: selfie,
    );
  }
}
