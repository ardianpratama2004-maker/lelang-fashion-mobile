import '../../../data/api/api_client.dart';
import '../../../data/models/auction_product.dart';
import '../../../data/models/auction_product_page.dart';
import '../domain/auction_repository.dart';

class ApiAuctionRepository implements AuctionRepository {
  const ApiAuctionRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<AuctionProduct>> products({String? status, String? query}) {
    return _api.auctionProducts(status: status, query: query);
  }

  @override
  Future<AuctionProductPage> productPage({
    String? status,
    String? query,
    int page = 1,
  }) {
    return _api.auctionProductsPage(status: status, query: query, page: page);
  }

  @override
  Future<AuctionProduct> product(int id) {
    return _api.auctionProduct(id);
  }

  @override
  Future<AuctionProduct> placeBid(int productId, int amount) {
    return _api.placeBid(productId, amount);
  }

  @override
  Future<AuctionProductPage> favoriteProductPage({int page = 1}) {
    return _api.favoriteAuctionProductsPage(page: page);
  }

  @override
  Future<AuctionProduct> favoriteProduct(int productId) {
    return _api.favoriteAuctionProduct(productId);
  }

  @override
  Future<AuctionProduct> unfavoriteProduct(int productId) {
    return _api.unfavoriteAuctionProduct(productId);
  }
}
