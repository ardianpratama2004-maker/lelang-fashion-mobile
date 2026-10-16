import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/auction_product.dart';
import '../../../data/models/bid_record.dart';
import '../../chat/domain/chat_repository.dart';
import '../domain/auction_repository.dart';
import '../../../utils/currency_input_formatter.dart';

class AuctionDetailScreen extends StatefulWidget {
  const AuctionDetailScreen({
    required this.repository,
    required this.chatRepository,
    required this.productId,
    this.currentUserId,
    super.key,
  });

  final AuctionRepository repository;
  final ChatRepository chatRepository;
  final int productId;
  final int? currentUserId;

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen>
    with TickerProviderStateMixin {
  final _amount = TextEditingController();
  AuctionProduct? _product;
  Timer? _timer;
  Timer? _feedbackTimer;
  bool _loading = true;
  bool _submitting = false;
  bool _showBidVictory = false;
  bool _showOutbid = false;
  bool _openingChat = false;
  bool _favoriteSubmitting = false;
  int? _lastSubmittedAmount;
  int? _outbidAmount;

  late final AnimationController _celebrationController;
  late final AnimationController _outbidController;
  late final AnimationController _pricePulseController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _outbidController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _pricePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _load();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackTimer?.cancel();
    _amount.dispose();
    _celebrationController.dispose();
    _outbidController.dispose();
    _pricePulseController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final previous = _product;
    if (!silent) setState(() => _loading = true);
    try {
      final product = await widget.repository.product(widget.productId);
      if (!mounted) return;

      _detectOutbid(previous, product, silent: silent);

      setState(() => _product = product);

      if (previous != null &&
          product.currentHighestBid > previous.currentHighestBid) {
        _pricePulseController.forward(from: 0);
      }
    } catch (error) {
      if (mounted && !silent) showError(context, error.toString());
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  void _detectOutbid(
    AuctionProduct? previous,
    AuctionProduct product, {
    required bool silent,
  }) {
    if (!silent || previous == null || widget.currentUserId == null) return;
    if (product.currentHighestBid <= previous.currentHighestBid) return;

    final previousLeader = previous.bids.isNotEmpty
        ? previous.bids.first
        : null;
    final newLeader = product.bids.isNotEmpty ? product.bids.first : null;
    final wasLeading = previousLeader?.userId == widget.currentUserId;
    final stillLeading = newLeader?.userId == widget.currentUserId;

    if (wasLeading && !stillLeading) {
      HapticFeedback.mediumImpact();
      setState(() {
        _showBidVictory = false;
        _showOutbid = true;
        _outbidAmount = product.currentHighestBid;
      });
      _outbidController.forward(from: 0);
      _hideFeedbackAfter(const Duration(seconds: 5), outbid: true);
    }
  }

  Future<void> _bid() async {
    final amount = int.tryParse(_amount.text.replaceAll(RegExp(r'\D'), ''));
    if (amount == null) {
      showError(context, 'Nominal bid tidak valid.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final product = await widget.repository.placeBid(
        widget.productId,
        amount,
      );
      _amount.clear();
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _product = product;
          _lastSubmittedAmount = amount;
          _showBidVictory = true;
          _showOutbid = false;
        });
        _celebrationController.forward(from: 0);
        _pricePulseController.forward(from: 0);
        _hideFeedbackAfter(const Duration(seconds: 4), victory: true);
      }
    } catch (error) {
      if (mounted) showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openChat() async {
    setState(() => _openingChat = true);
    try {
      final thread = await widget.chatRepository.startForProduct(
        widget.productId,
      );
      if (mounted) context.push('/chat/${thread.id}');
    } catch (error) {
      if (mounted) showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final product = _product;
    if (product == null || _favoriteSubmitting) return;

    final next = !product.isFavorited;
    setState(() {
      _favoriteSubmitting = true;
      _product = product.copyWith(isFavorited: next);
    });

    try {
      final updated = next
          ? await widget.repository.favoriteProduct(product.id)
          : await widget.repository.unfavoriteProduct(product.id);
      if (mounted) setState(() => _product = updated);
    } catch (error) {
      if (mounted) {
        setState(() => _product = product);
        showError(context, error.toString());
      }
    } finally {
      if (mounted) setState(() => _favoriteSubmitting = false);
    }
  }

  void _hideFeedbackAfter(
    Duration duration, {
    bool victory = false,
    bool outbid = false,
  }) {
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() {
        if (victory) _showBidVictory = false;
        if (outbid) _showOutbid = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final biddingActive = product?.status == 'active';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.brandSoft,
        foregroundColor: AppColors.ink,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(AppAssets.logo),
            ),
            const SizedBox(width: 8),
            const Text('Detail Lelang'),
          ],
        ),
        actions: [
          if (product != null)
            IconButton(
              onPressed: _favoriteSubmitting ? null : _toggleFavorite,
              icon: Icon(
                product.isFavorited ? Icons.favorite : Icons.favorite_border,
                color: product.isFavorited
                    ? AppColors.accent500
                    : AppColors.brand800,
              ),
              tooltip: product.isFavorited
                  ? 'Hapus dari favorit'
                  : 'Tambah ke favorit',
            ),
        ],
      ),
      bottomNavigationBar: product != null && biddingActive
          ? AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: _BidConsoleCard(
                    product: product,
                    amount: _amount,
                    submitting: _submitting,
                    isLeading:
                        product.bids.isNotEmpty &&
                        product.bids.first.userId == widget.currentUserId,
                    onBid: _bid,
                  ),
                ),
              ),
            )
          : null,
      body: AppBackground(
        child: _loading && product == null
            ? const Center(child: CircularProgressIndicator())
            : product == null
            ? ErrorState(message: 'Produk tidak ditemukan.', onRetry: _load)
            : RefreshIndicator(
                onRefresh: () => _load(),
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    biddingActive ? 28 : 16,
                  ),
                  children: [
                    _AuctionPulseHeader(
                      product: product,
                      currentUserId: widget.currentUserId,
                      pricePulse: _pricePulseController,
                      showVictory: _showBidVictory,
                      showOutbid: _showOutbid,
                      lastSubmittedAmount: _lastSubmittedAmount,
                      outbidAmount: _outbidAmount,
                      celebration: _celebrationController,
                      outbidAnimation: _outbidController,
                    ),
                    const SizedBox(height: 10),
                    GlassSurface(
                      padding: EdgeInsets.zero,
                      radius: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProductImage(url: product.imageUrl, height: 250),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    StatusBadge(status: product.status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${product.category} - ${product.condition}',
                                ),
                                if (product.brand != null)
                                  Text('Brand: ${product.brand}'),
                                if (product.size != null)
                                  Text('Ukuran: ${product.size}'),
                                const Divider(height: 22),
                                Text(product.description),
                                const Divider(height: 22),
                                InfoRow(
                                  label: 'Harga awal',
                                  value: money(product.startingPrice),
                                ),
                                InfoRow(
                                  label: 'Harga tertinggi',
                                  value: money(product.currentHighestBid),
                                ),
                                InfoRow(
                                  label: 'Bid minimal',
                                  value: money(product.minimumNextBid),
                                ),
                                InfoRow(
                                  label: 'Mulai',
                                  value: dateText(product.startsAt),
                                ),
                                InfoRow(
                                  label: 'Selesai',
                                  value: dateText(product.endsAt),
                                ),
                                if (product.winnerName != null)
                                  InfoRow(
                                    label: 'Pemenang',
                                    value: product.winnerName!,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openingChat ? null : _openChat,
                      icon: _openingChat
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Icon(Icons.support_agent),
                      label: Text(
                        _openingChat ? 'Membuka chat...' : 'Chat Admin',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Leaderboard Bid',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (product.bids.isNotEmpty)
                          Chip(
                            backgroundColor: AppColors.brand50,
                            side: BorderSide(
                              color: AppColors.brand200.withValues(alpha: 0.8),
                            ),
                            avatar: const Icon(
                              Icons.local_fire_department,
                              color: AppColors.brand700,
                            ),
                            label: Text(
                              '${product.bids.length} bid',
                              style: const TextStyle(
                                color: AppColors.brand800,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (product.bids.isEmpty)
                      const EmptyState(message: 'Belum ada bid.')
                    else
                      for (final entry in product.bids.indexed)
                        _LeaderboardBidTile(
                          bid: entry.$2,
                          rank: entry.$1 + 1,
                          isMine: entry.$2.userId == widget.currentUserId,
                        ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AuctionPulseHeader extends StatelessWidget {
  const _AuctionPulseHeader({
    required this.product,
    required this.currentUserId,
    required this.pricePulse,
    required this.showVictory,
    required this.showOutbid,
    required this.lastSubmittedAmount,
    required this.outbidAmount,
    required this.celebration,
    required this.outbidAnimation,
  });

  final AuctionProduct product;
  final int? currentUserId;
  final Animation<double> pricePulse;
  final bool showVictory;
  final bool showOutbid;
  final int? lastSubmittedAmount;
  final int? outbidAmount;
  final Animation<double> celebration;
  final Animation<double> outbidAnimation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final leading =
        product.bids.isNotEmpty && product.bids.first.userId == currentUserId;

    return GlassSurface(
      padding: EdgeInsets.zero,
      radius: 20,
      child: Stack(
        children: [
          if (showVictory)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: celebration,
                  builder: (context, _) => CustomPaint(
                    painter: _ConfettiPainter(progress: celebration.value),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.military_tech,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bid Arena',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            leading
                                ? 'Kamu sedang memimpin'
                                : 'Rebut posisi teratas',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: leading
                          ? const _ArenaPill(
                              key: ValueKey('leading'),
                              icon: Icons.emoji_events,
                              label: 'Leading',
                              color: AppColors.brand700,
                            )
                          : const _ArenaPill(
                              key: ValueKey('chasing'),
                              icon: Icons.speed,
                              label: 'Chasing',
                              color: AppColors.accent500,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: pricePulse,
                  builder: (context, child) {
                    final scale =
                        1 + (math.sin(pricePulse.value * math.pi) * 0.055);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.brand800, AppColors.ink],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Harga tertinggi saat ini',
                          style: TextStyle(
                            color: colorScheme.onPrimary.withValues(
                              alpha: 0.76,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          money(product.currentHighestBid),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: colorScheme.onPrimary,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Bid berikutnya mulai ${money(product.minimumNextBid)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onPrimary.withValues(
                                    alpha: 0.86,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: showVictory
                      ? _FeedbackBanner(
                          key: const ValueKey('victory'),
                          animation: celebration,
                          icon: Icons.bolt,
                          title: 'Bid masuk. Kamu naik ke papan atas.',
                          message: lastSubmittedAmount == null
                              ? 'Pantau terus, penawar lain bisa menyusul kapan saja.'
                              : 'Nominal ${money(lastSubmittedAmount!)} terkunci sebagai bid terbaru.',
                          color: AppColors.brand700,
                        )
                      : showOutbid
                      ? _FeedbackBanner(
                          key: const ValueKey('outbid'),
                          animation: outbidAnimation,
                          icon: Icons.warning_amber_rounded,
                          title: 'Kamu baru saja tersalip.',
                          message:
                              'Harga tertinggi naik ke ${money(outbidAmount ?? product.currentHighestBid)}. Balas dengan bid lebih tinggi.',
                          color: AppColors.accent500,
                        )
                      : const SizedBox.shrink(key: ValueKey('empty-feedback')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArenaPill extends StatelessWidget {
  const _ArenaPill({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.animation,
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    super.key,
  });

  final Animation<double> animation;
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final curved = Curves.easeOutBack.transform(
          animation.value.clamp(0, 1),
        );
        return Opacity(
          opacity: animation.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - curved)),
            child: Transform.scale(scale: 0.96 + (0.04 * curved), child: child),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color,
              foregroundColor: Colors.white,
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(message, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BidConsoleCard extends StatelessWidget {
  const _BidConsoleCard({
    required this.product,
    required this.amount,
    required this.submitting,
    required this.isLeading,
    required this.onBid,
  });

  final AuctionProduct product;
  final TextEditingController amount;
  final bool submitting;
  final bool isLeading;
  final VoidCallback onBid;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassSurface(
      radius: 20,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kirim Bid',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isLeading)
                  const _ArenaPill(
                    icon: Icons.shield,
                    label: 'Pertahankan',
                    color: AppColors.brand700,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    scrollPadding: const EdgeInsets.only(bottom: 96),
                    decoration: InputDecoration(
                      hintText: 'Min. ${money(product.minimumNextBid)}',
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedScale(
                  scale: submitting ? 0.98 : 1,
                  duration: const Duration(milliseconds: 160),
                  child: FilledButton(
                    onPressed: submitting ? null : onBid,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(98, 46),
                    ),
                    child: submitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.gavel, size: 18),
                              SizedBox(width: 6),
                              Text('Bid'),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: product.bids.isEmpty
                        ? 0.08
                        : (product.bids.length / 12).clamp(0.12, 1).toDouble(),
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  product.bids.isEmpty
                      ? 'Bid pertama'
                      : '${product.bids.length} bid',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardBidTile extends StatelessWidget {
  const _LeaderboardBidTile({
    required this.bid,
    required this.rank,
    required this.isMine,
  });

  final BidRecord bid;
  final int rank;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLeader = rank == 1;
    final rankColor = isLeader
        ? AppColors.accent500
        : isMine
        ? colorScheme.primary
        : colorScheme.outline;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: Duration(milliseconds: 220 + (rank * 28).clamp(0, 220)),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: GlassSurface(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.zero,
        radius: 18,
        shadow: false,
        color: isMine
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : AppColors.glass,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: rankColor.withValues(alpha: 0.14),
            foregroundColor: rankColor,
            child: Icon(isLeader ? Icons.emoji_events : Icons.person),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  bid.userName ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (isMine)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Kamu',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text('#$rank · ${dateText(bid.createdAt)}'),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(bid.amount),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (isLeader)
                const Text(
                  'Teratas',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final colors = <Color>[
      AppColors.brand700,
      AppColors.brand500,
      AppColors.brand200,
      AppColors.accent500,
      AppColors.accent100,
    ];

    for (var i = 0; i < 28; i++) {
      final seed = i * 37.0;
      final startX = (math.sin(seed) + 1) * size.width / 2;
      final fall = Curves.easeOut.transform(progress) * (58 + (i % 5) * 18);
      final drift = math.cos(seed) * progress * 34;
      final y = 18 + fall + (i % 4) * 10;
      final x = startX + drift;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      paint.color = colors[i % colors.length].withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * math.pi * (i.isEven ? 1 : -1));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -6, 6, 12),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
