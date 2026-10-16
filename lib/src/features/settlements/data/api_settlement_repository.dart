import '../../../data/api/api_client.dart';
import '../../../data/models/auction_settlement.dart';
import '../../../data/models/second_chance_offer.dart';
import '../domain/settlement_repository.dart';

class ApiSettlementRepository implements SettlementRepository {
  const ApiSettlementRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<AuctionSettlement>> mySettlements() {
    return _api.mySettlements();
  }

  @override
  Future<List<SecondChanceOffer>> secondChanceOffers() {
    return _api.secondChanceOffers();
  }

  @override
  Future<String> startPayment(int settlementId) {
    return _api.startSettlementPayment(settlementId);
  }

  @override
  Future<void> acceptSecondChance(int offerId) {
    return _api.acceptSecondChance(offerId);
  }

  @override
  Future<void> rejectSecondChance(int offerId) {
    return _api.rejectSecondChance(offerId);
  }
}
