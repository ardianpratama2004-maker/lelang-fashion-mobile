import '../../core/utils/date_parser.dart';
import 'bid_record.dart';

class AuctionProduct {
  const AuctionProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.startingPrice,
    required this.bidIncrement,
    required this.currentHighestBid,
    required this.minimumNextBid,
    required this.status,
    required this.bids,
    required this.isFavorited,
    this.brand,
    this.size,
    this.imageUrl,
    this.startsAt,
    this.endsAt,
    this.closedAt,
    this.winnerName,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final String condition;
  final String? brand;
  final String? size;
  final String? imageUrl;
  final int startingPrice;
  final int bidIncrement;
  final int currentHighestBid;
  final int minimumNextBid;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String status;
  final bool isFavorited;
  final DateTime? closedAt;
  final String? winnerName;
  final List<BidRecord> bids;

  factory AuctionProduct.fromJson(Map<String, dynamic> json) {
    final bids = json['bids'] as List<dynamic>? ?? const [];
    final bidRecords =
        bids.cast<Map<String, dynamic>>().map(BidRecord.fromJson).toList()
          ..sort((a, b) {
            final amountCompare = b.amount.compareTo(a.amount);
            if (amountCompare != 0) return amountCompare;
            final aCreated = a.createdAt;
            final bCreated = b.createdAt;
            if (aCreated == null || bCreated == null) return 0;
            return aCreated.compareTo(bCreated);
          });
    final winner = json['winner'];
    return AuctionProduct(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      condition: json['condition'] as String,
      brand: json['brand'] as String?,
      size: json['size'] as String?,
      imageUrl: json['image_url'] as String?,
      startingPrice: json['starting_price'] as int,
      bidIncrement: json['bid_increment'] as int,
      currentHighestBid: json['current_highest_bid'] as int,
      minimumNextBid: json['minimum_next_bid'] as int,
      startsAt: parseDate(json['starts_at']),
      endsAt: parseDate(json['ends_at']),
      status: json['status'] as String,
      isFavorited: json['is_favorited'] as bool? ?? false,
      closedAt: parseDate(json['closed_at']),
      winnerName: winner is Map<String, dynamic>
          ? winner['name'] as String?
          : null,
      bids: bidRecords,
    );
  }

  AuctionProduct copyWith({bool? isFavorited}) {
    return AuctionProduct(
      id: id,
      title: title,
      description: description,
      category: category,
      condition: condition,
      startingPrice: startingPrice,
      bidIncrement: bidIncrement,
      currentHighestBid: currentHighestBid,
      minimumNextBid: minimumNextBid,
      status: status,
      bids: bids,
      isFavorited: isFavorited ?? this.isFavorited,
      brand: brand,
      size: size,
      imageUrl: imageUrl,
      startsAt: startsAt,
      endsAt: endsAt,
      closedAt: closedAt,
      winnerName: winnerName,
    );
  }
}
