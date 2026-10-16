import 'auction_product.dart';

class AuctionProductPage {
  const AuctionProductPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });

  final List<AuctionProduct> items;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;

  factory AuctionProductPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? const [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    return AuctionProductPage(
      items: data
          .cast<Map<String, dynamic>>()
          .map(AuctionProduct.fromJson)
          .toList(),
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
    );
  }
}
