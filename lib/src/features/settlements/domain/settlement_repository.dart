import '../../../data/models/auction_settlement.dart';
import '../../../data/models/second_chance_offer.dart';

abstract class SettlementRepository {
  Future<List<AuctionSettlement>> mySettlements();

  Future<List<SecondChanceOffer>> secondChanceOffers();

  Future<String> startPayment(int settlementId);

  Future<void> acceptSecondChance(int offerId);

  Future<void> rejectSecondChance(int offerId);
}
