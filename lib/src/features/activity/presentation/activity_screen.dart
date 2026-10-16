import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/product_image.dart';
import '../../../data/models/auction_product.dart';
import '../../../data/models/auction_settlement.dart';
import '../../../data/models/bid_record.dart';
import '../../../data/models/second_chance_offer.dart';
import '../../bids/domain/bid_repository.dart';
import '../../settlements/domain/settlement_repository.dart';
import '../../settlements/presentation/payment_checkout.dart';
import '../../wins/domain/win_repository.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({
    required this.bidRepository,
    required this.winRepository,
    required this.settlementRepository,
    required this.initialTab,
    super.key,
  });

  final BidRepository bidRepository;
  final WinRepository winRepository;
  final SettlementRepository settlementRepository;
  final String initialTab;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabs;
  late Future<List<BidRecord>> _bidsFuture;
  late Future<List<AuctionProduct>> _winsFuture;
  late Future<SettlementHubData> _settlementFuture;

  static const _tabKeys = ['bid', 'menang', 'bayar', 'offer'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs = TabController(
      length: _tabKeys.length,
      vsync: this,
      initialIndex: _tabIndex(widget.initialTab),
    );
    _reload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(_reload);
  }

  @override
  void didUpdateWidget(covariant ActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tabs.animateTo(_tabIndex(widget.initialTab));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabs.dispose();
    super.dispose();
  }

  static int _tabIndex(String key) {
    final index = _tabKeys.indexOf(key);
    return index < 0 ? 0 : index;
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait([_bidsFuture, _winsFuture, _settlementFuture]);
  }

  void _reload() {
    _bidsFuture = widget.bidRepository.myBids();
    _winsFuture = widget.winRepository.myWins();
    _settlementFuture = _loadSettlementData();
  }

  Future<SettlementHubData> _loadSettlementData() async {
    final results = await Future.wait([
      widget.settlementRepository.mySettlements(),
      widget.settlementRepository.secondChanceOffers(),
    ]);
    return SettlementHubData(
      settlements: results[0] as List<AuctionSettlement>,
      offers: results[1] as List<SecondChanceOffer>,
    );
  }

  Future<void> _respondOffer(SecondChanceOffer offer, bool accept) async {
    try {
      if (accept) {
        await widget.settlementRepository.acceptSecondChance(offer.id);
      } else {
        await widget.settlementRepository.rejectSecondChance(offer.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? 'Offer diterima.' : 'Offer ditolak.')),
      );
      await _refresh();
    } catch (error) {
      if (mounted) showError(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _ActivityHeader(tabController: _tabs),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _FutureListTab<BidRecord>(
                future: _bidsFuture,
                onRefresh: _refresh,
                emptyMessage: 'Belum ada bid yang dikirim.',
                emptyIcon: Icons.gavel_outlined,
                itemBuilder: (bid) => _BidActivityCard(bid: bid),
              ),
              _FutureListTab<AuctionProduct>(
                future: _winsFuture,
                onRefresh: _refresh,
                emptyMessage: 'Belum ada lelang yang dimenangkan.',
                emptyIcon: Icons.emoji_events_outlined,
                itemBuilder: (product) => _WinActivityCard(product: product),
              ),
              _FutureDataTab<SettlementHubData>(
                future: _settlementFuture,
                onRefresh: _refresh,
                builder: (data) => _SettlementList(
                  settlements: data.settlements,
                  onStartPayment: (settlement) => openSettlementCheckout(
                    context,
                    widget.settlementRepository,
                    settlement.id,
                  ),
                ),
              ),
              _FutureDataTab<SettlementHubData>(
                future: _settlementFuture,
                onRefresh: _refresh,
                builder: (data) =>
                    _OfferList(offers: data.offers, onRespond: _respondOffer),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityHeader extends StatelessWidget {
  const _ActivityHeader({required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Icon(Icons.dashboard, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktivitas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text(
                      'Bid, kemenangan, pembayaran, dan offer.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.zinc500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: tabController,
            builder: (context, _) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ActivityTabButton(
                      label: 'Bid Saya',
                      selected: tabController.index == 0,
                      onTap: () => tabController.animateTo(0),
                    ),
                    _ActivityTabButton(
                      label: 'Menang',
                      selected: tabController.index == 1,
                      onTap: () => tabController.animateTo(1),
                    ),
                    _ActivityTabButton(
                      label: 'Bayar',
                      selected: tabController.index == 2,
                      onTap: () => tabController.animateTo(2),
                    ),
                    _ActivityTabButton(
                      label: 'Offer',
                      selected: tabController.index == 3,
                      onTap: () => tabController.animateTo(3),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityTabButton extends StatelessWidget {
  const _ActivityTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CompactPill(label: label, selected: selected, onTap: onTap),
    );
  }
}

class _FutureListTab<T> extends StatelessWidget {
  const _FutureListTab({
    required this.future,
    required this.onRefresh,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.itemBuilder,
  });

  final Future<List<T>> future;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return _FutureDataTab<List<T>>(
      future: future,
      onRefresh: onRefresh,
      builder: (items) {
        if (items.isEmpty) {
          return EmptyState(message: emptyMessage, icon: emptyIcon);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 108),
          itemBuilder: (context, index) => itemBuilder(items[index]),
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemCount: items.length,
        );
      },
    );
  }
}

class _FutureDataTab<T> extends StatelessWidget {
  const _FutureDataTab({
    required this.future,
    required this.onRefresh,
    required this.builder,
  });

  final Future<T> future;
  final Future<void> Function() onRefresh;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: FutureBuilder<T>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.only(top: 88),
              children: const [Center(child: CircularProgressIndicator())],
            );
          }
          if (snapshot.hasError) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                ErrorState(
                  message: snapshot.error.toString(),
                  onRetry: onRefresh,
                ),
              ],
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const EmptyState(message: 'Data belum tersedia.');
          }
          return builder(data);
        },
      ),
    );
  }
}

class _BidActivityCard extends StatelessWidget {
  const _BidActivityCard({required this.bid});

  final BidRecord bid;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      radius: 18,
      shadow: false,
      child: ListTile(
        leading: const _ActivityIcon(
          icon: Icons.gavel,
          color: AppColors.brand700,
        ),
        title: Text(bid.productTitle ?? '-'),
        subtitle: Text(dateText(bid.createdAt)),
        trailing: Text(
          money(bid.amount),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _WinActivityCard extends StatelessWidget {
  const _WinActivityCard({required this.product});

  final AuctionProduct product;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      radius: 18,
      shadow: false,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            child: ProductImage(url: product.imageUrl, height: 52),
          ),
        ),
        title: Text(product.title),
        subtitle: Text('Ditutup ${dateText(product.closedAt)}'),
        trailing: Text(
          money(product.currentHighestBid),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _SettlementList extends StatelessWidget {
  const _SettlementList({
    required this.settlements,
    required this.onStartPayment,
  });

  final List<AuctionSettlement> settlements;
  final ValueChanged<AuctionSettlement> onStartPayment;

  @override
  Widget build(BuildContext context) {
    if (settlements.isEmpty) {
      return const EmptyState(
        message: 'Belum ada pelunasan.',
        icon: Icons.payments_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 108),
      itemBuilder: (context, index) {
        final settlement = settlements[index];
        return GlassSurface(
          padding: EdgeInsets.zero,
          radius: 18,
          shadow: false,
          child: ListTile(
            leading: const _ActivityIcon(
              icon: Icons.payments,
              color: AppColors.accent700,
            ),
            title: Text(settlement.productTitle),
            subtitle: Text(
              '${money(settlement.amount)} · ${settlementStatusLabel(settlement.status)}\nDeadline ${dateText(settlement.paymentDueAt)}${settlement.paymentAttempt == null ? '' : '\n${paymentAttemptStatusLabel(settlement.paymentAttempt!.status)}'}',
            ),
            isThreeLine: true,
            trailing: settlement.status == 'menunggu_pembayaran'
                ? IconButton.filled(
                    onPressed: () => onStartPayment(settlement),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.brand800,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(
                      Icons.payment,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Bayar sekarang',
                  )
                : null,
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemCount: settlements.length,
    );
  }
}

class _OfferList extends StatelessWidget {
  const _OfferList({required this.offers, required this.onRespond});

  final List<SecondChanceOffer> offers;
  final Future<void> Function(SecondChanceOffer offer, bool accept) onRespond;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return const EmptyState(
        message: 'Belum ada second-chance offer.',
        icon: Icons.local_offer_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 108),
      itemBuilder: (context, index) {
        final offer = offers[index];
        return GlassSurface(
          padding: EdgeInsets.zero,
          radius: 18,
          shadow: false,
          child: ListTile(
            leading: const _ActivityIcon(
              icon: Icons.local_offer,
              color: AppColors.gold700,
            ),
            title: Text(offer.productTitle),
            subtitle: Text(
              '${money(offer.amount)} · ${settlementStatusLabel(offer.status)}\nBerlaku sampai ${dateText(offer.expiresAt)}',
            ),
            isThreeLine: true,
            trailing: offer.status == 'ditawarkan'
                ? Wrap(
                    spacing: 4,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => onRespond(offer, true),
                        icon: const Icon(Icons.check),
                        tooltip: 'Terima',
                      ),
                      IconButton.outlined(
                        onPressed: () => onRespond(offer, false),
                        icon: const Icon(Icons.close),
                        tooltip: 'Tolak',
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemCount: offers.length,
    );
  }
}

class _ActivityIcon extends StatelessWidget {
  const _ActivityIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class SettlementHubData {
  const SettlementHubData({required this.settlements, required this.offers});

  final List<AuctionSettlement> settlements;
  final List<SecondChanceOffer> offers;
}
