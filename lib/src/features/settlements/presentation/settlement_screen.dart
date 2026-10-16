import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../data/models/auction_settlement.dart';
import '../../../data/models/second_chance_offer.dart';
import '../domain/settlement_repository.dart';
import 'payment_checkout.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({required this.repository, super.key});

  final SettlementRepository repository;

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen>
    with WidgetsBindingObserver {
  late Future<SettlementHubData> _future = _load();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<SettlementHubData> _load() async {
    final results = await Future.wait([
      widget.repository.mySettlements(),
      widget.repository.secondChanceOffers(),
    ]);
    return SettlementHubData(
      settlements: results[0] as List<AuctionSettlement>,
      offers: results[1] as List<SecondChanceOffer>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
  }

  Future<void> _respondOffer(SecondChanceOffer offer, bool accept) async {
    try {
      if (accept) {
        await widget.repository.acceptSecondChance(offer.id);
      } else {
        await widget.repository.rejectSecondChance(offer.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Offer diterima.' : 'Offer ditolak.'),
          ),
        );
        _refresh();
      }
    } catch (error) {
      if (mounted) showError(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          const SectionHeader(
            title: 'Pelunasan',
            subtitle: 'Pantau status dan lanjutkan pembayaran.',
          ),
          const SizedBox(height: 14),
          FutureBuilder<SettlementHubData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 64),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return ErrorState(
                  message: snapshot.error.toString(),
                  onRetry: _refresh,
                );
              }

              final data =
                  snapshot.data ??
                  const SettlementHubData(settlements: [], offers: []);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Second-Chance Offer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (data.offers.isEmpty)
                    const EmptyState(message: 'Belum ada second-chance offer.')
                  else
                    for (final offer in data.offers) ...[
                      GlassSurface(
                        padding: EdgeInsets.zero,
                        radius: 18,
                        shadow: false,
                        child: ListTile(
                          title: Text(offer.productTitle),
                          subtitle: Text(
                            '${money(offer.amount)} · ${settlementStatusLabel(offer.status)}\nBerlaku sampai ${dateText(offer.expiresAt)}',
                          ),
                          isThreeLine: true,
                          trailing: offer.status == 'ditawarkan'
                              ? Wrap(
                                  spacing: 6,
                                  children: [
                                    IconButton.filled(
                                      onPressed: () =>
                                          _respondOffer(offer, true),
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.brand700,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                      ),
                                      tooltip: 'Terima',
                                    ),
                                    IconButton.filled(
                                      onPressed: () =>
                                          _respondOffer(offer, false),
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.accent500,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      tooltip: 'Tolak',
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  const SizedBox(height: 14),
                  Text(
                    'Pelunasan Saya',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (data.settlements.isEmpty)
                    const EmptyState(message: 'Belum ada pelunasan.')
                  else
                    for (final settlement in data.settlements) ...[
                      GlassSurface(
                        padding: EdgeInsets.zero,
                        radius: 18,
                        shadow: false,
                        child: ListTile(
                          title: Text(settlement.productTitle),
                          subtitle: Text(
                            '${money(settlement.amount)} · ${settlementStatusLabel(settlement.status)}\nDeadline ${dateText(settlement.paymentDueAt)}${settlement.paymentAttempt == null ? '' : '\n${paymentAttemptStatusLabel(settlement.paymentAttempt!.status)}'}',
                          ),
                          isThreeLine: true,
                          trailing: settlement.status == 'menunggu_pembayaran'
                              ? IconButton.filled(
                                  onPressed: () => openSettlementCheckout(
                                    context,
                                    widget.repository,
                                    settlement.id,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.brand800,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(
                                    Icons.payment,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'Bayar sekarang',
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class SettlementHubData {
  const SettlementHubData({required this.settlements, required this.offers});

  final List<AuctionSettlement> settlements;
  final List<SecondChanceOffer> offers;
}
