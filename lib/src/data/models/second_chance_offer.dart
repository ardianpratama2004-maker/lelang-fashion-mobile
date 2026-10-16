import '../../core/utils/date_parser.dart';

class SecondChanceOffer {
  const SecondChanceOffer({
    required this.id,
    required this.productTitle,
    required this.amount,
    required this.status,
    this.expiresAt,
  });

  final int id;
  final String productTitle;
  final int amount;
  final String status;
  final DateTime? expiresAt;

  factory SecondChanceOffer.fromJson(Map<String, dynamic> json) {
    final product = json['auction_product'] as Map<String, dynamic>? ?? {};
    return SecondChanceOffer(
      id: json['id'] as int,
      productTitle: product['title'] as String? ?? '-',
      amount: json['amount'] as int,
      status: json['status'] as String,
      expiresAt: parseDate(json['expires_at']),
    );
  }
}
