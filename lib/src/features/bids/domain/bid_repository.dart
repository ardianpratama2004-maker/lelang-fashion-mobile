import '../../../data/models/bid_record.dart';

abstract class BidRepository {
  Future<List<BidRecord>> myBids();
}
