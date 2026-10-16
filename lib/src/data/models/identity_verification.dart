import '../../core/utils/date_parser.dart';

class IdentityVerification {
  const IdentityVerification({
    required this.id,
    required this.name,
    required this.status,
    this.rejectionReason,
    this.createdAt,
  });

  final int id;
  final String name;
  final String status;
  final String? rejectionReason;
  final DateTime? createdAt;

  factory IdentityVerification.fromJson(Map<String, dynamic> json) {
    return IdentityVerification(
      id: json['id'] as int,
      name: json['nama_ktp'] as String,
      status: json['status'] as String,
      rejectionReason: json['alasan_penolakan'] as String?,
      createdAt: parseDate(json['created_at']),
    );
  }
}
