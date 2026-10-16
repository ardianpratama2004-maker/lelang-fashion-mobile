class UserAccount {
  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.creditScore,
    required this.whatsappVerified,
    required this.biddingLocked,
    required this.ekycStatus,
    this.whatsapp,
    this.biddingLockedReason,
  });

  final int id;
  final String name;
  final String email;
  final String? whatsapp;
  final int creditScore;
  final bool whatsappVerified;
  final bool biddingLocked;
  final String? biddingLockedReason;
  final String ekycStatus;

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      whatsapp: json['nomor_whatsapp'] as String?,
      creditScore: json['credit_score'] as int? ?? 100,
      whatsappVerified: json['whatsapp_verified'] as bool? ?? false,
      biddingLocked: json['bidding_locked'] as bool? ?? false,
      biddingLockedReason: json['bidding_locked_reason'] as String?,
      ekycStatus: json['ekyc_status'] as String? ?? 'belum_diajukan',
    );
  }
}
