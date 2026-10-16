import '../../../data/models/auction_product.dart';

abstract class WinRepository {
  Future<List<AuctionProduct>> myWins();
}
