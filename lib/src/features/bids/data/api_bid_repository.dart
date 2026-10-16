import '../../../data/api/api_client.dart';
import '../../../data/models/bid_record.dart';
import '../domain/bid_repository.dart';

class ApiBidRepository implements BidRepository {
  const ApiBidRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<BidRecord>> myBids() {
    return _api.myBids();
  }
}
