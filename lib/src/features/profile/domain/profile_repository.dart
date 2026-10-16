import 'package:image_picker/image_picker.dart';

import '../../../data/models/identity_verification.dart';
import '../../../data/models/user_account.dart';

abstract class ProfileRepository {
  Future<UserAccount> me();

  Future<UserAccount> resendWhatsappOtp();

  Future<UserAccount> updateWhatsapp(String whatsapp);

  Future<UserAccount> verifyWhatsappOtp(String code);

  Future<IdentityVerification?> identityVerification();

  Future<IdentityVerification> submitIdentityVerification({
    required String nik,
    required String name,
    required XFile ktp,
    required XFile selfie,
  });
}
