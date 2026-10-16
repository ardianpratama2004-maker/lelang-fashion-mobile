import '../../core/utils/date_parser.dart';

class AuctionSettlement {
  const AuctionSettlement({
    required this.id,
    required this.productTitle,
    required this.amount,
    required this.status,
    this.paymentDueAt,
    this.paidAt,
    this.paymentAttempt,
  });

  final int id;
  final String productTitle;
  final int amount;
  final String status;
  final DateTime? paymentDueAt;
  final DateTime? paidAt;
  final AuctionPaymentAttempt? paymentAttempt;

  factory AuctionSettlement.fromJson(Map<String, dynamic> json) {
    final product = json['auction_product'] as Map<String, dynamic>? ?? {};
    final attemptJson = json['payment_attempt'] as Map<String, dynamic>?;
    return AuctionSettlement(
      id: json['id'] as int,
      productTitle: product['title'] as String? ?? '-',
      amount: json['amount'] as int,
      status: json['status'] as String,
      paymentDueAt: parseDate(json['payment_due_at']),
      paidAt: parseDate(json['paid_at']),
      paymentAttempt: attemptJson == null
          ? null
          : AuctionPaymentAttempt.fromJson(attemptJson),
    );
  }
}

class AuctionPaymentAttempt {
  const AuctionPaymentAttempt({
    required this.status,
    this.reference,
    this.paymentUrl,
    this.paymentMethod,
    this.expiresAt,
    this.paidAt,
    this.duplicateSuccess = false,
  });

  final String status;
  final String? reference;
  final String? paymentUrl;
  final String? paymentMethod;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final bool duplicateSuccess;

  factory AuctionPaymentAttempt.fromJson(Map<String, dynamic> json) {
    return AuctionPaymentAttempt(
      status: json['status'] as String? ?? 'menunggu',
      reference: json['reference'] as String?,
      paymentUrl: json['payment_url'] as String?,
      paymentMethod: json['payment_method'] as String?,
      expiresAt: parseDate(json['expires_at']),
      paidAt: parseDate(json['paid_at']),
      duplicateSuccess: json['duplicate_success'] as bool? ?? false,
    );
  }
}
