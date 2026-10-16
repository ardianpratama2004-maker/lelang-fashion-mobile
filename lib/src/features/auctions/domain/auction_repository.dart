import '../../../data/models/auction_product.dart';
import '../../../data/models/auction_product_page.dart';

abstract class AuctionRepository {
  Future<List<AuctionProduct>> products({String? status, String? query});

  Future<AuctionProductPage> productPage({
    String? status,
    String? query,
    int page,
  });

  Future<AuctionProduct> product(int id);

  Future<AuctionProduct> placeBid(int productId, int amount);

  Future<AuctionProductPage> favoriteProductPage({int page});

  Future<AuctionProduct> favoriteProduct(int productId);

  Future<AuctionProduct> unfavoriteProduct(int productId);
}
