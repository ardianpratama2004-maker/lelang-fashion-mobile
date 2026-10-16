import '../../../data/api/api_client.dart';
import '../../../data/models/auction_product.dart';
import '../domain/win_repository.dart';

class ApiWinRepository implements WinRepository {
  const ApiWinRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<AuctionProduct>> myWins() {
    return _api.myWins();
  }
}
