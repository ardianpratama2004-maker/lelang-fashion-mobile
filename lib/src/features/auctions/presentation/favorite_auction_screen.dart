import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../data/models/auction_product.dart';
import '../domain/auction_repository.dart';
import 'widgets/auction_product_card.dart';

class FavoriteAuctionScreen extends StatefulWidget {
  const FavoriteAuctionScreen({required this.repository, super.key});

  final AuctionRepository repository;

  @override
  State<FavoriteAuctionScreen> createState() => _FavoriteAuctionScreenState();
}

class _FavoriteAuctionScreenState extends State<FavoriteAuctionScreen> {
  final _scroll = ScrollController();
  final List<AuctionProduct> _products = [];
  final Set<int> _favoriteBusy = {};
  int _page = 1;
  bool _hasMore = true;
  bool _loadingInitial = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loadingMore || _loadingInitial || !_hasMore) {
      return;
    }

    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 420) {
      _loadMore();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _page = 1;
      _hasMore = true;
      _loadingInitial = true;
      _loadingMore = false;
      _error = null;
      _products.clear();
    });

    await _loadPage(1, replace: true);
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;

    setState(() => _loadingMore = true);
    await _loadPage(_page + 1);
  }

  Future<void> _loadPage(int page, {bool replace = false}) async {
    try {
      final result = await widget.repository.favoriteProductPage(page: page);
      if (!mounted) return;

      setState(() {
        if (replace) _products.clear();
        _products.addAll(result.items);
        _page = result.currentPage;
        _hasMore = result.hasMore;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() {
          _loadingInitial = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(AuctionProduct product) async {
    if (_favoriteBusy.contains(product.id)) return;

    setState(() {
      _favoriteBusy.add(product.id);
      _products.removeWhere((item) => item.id == product.id);
    });

    try {
      await widget.repository.unfavoriteProduct(product.id);
    } catch (error) {
      if (mounted) {
        setState(() => _products.add(product));
        showError(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _favoriteBusy.remove(product.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Lelang Disukai')),
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _FavoriteHeader(count: _products.length),
              const SizedBox(height: 10),
              if (_loadingInitial)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null && _products.isEmpty)
                ErrorState(message: _error.toString(), onRetry: _reload)
              else if (_products.isEmpty)
                const EmptyState(
                  message: 'Belum ada lelang yang disukai.',
                  icon: Icons.favorite_border,
                )
              else
                _FavoriteProductLayout(
                  products: _products,
                  onToggleFavorite: _toggleFavorite,
                  onOpenProduct: (product) async {
                    await context.push('/lelang/${product.id}');
                    _reload();
                  },
                ),
              if (_loadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!_hasMore && _products.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8),
                  child: Center(
                    child: Text(
                      'Semua favorit sudah tampil.',
                      style: TextStyle(
                        color: AppColors.zinc500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteHeader extends StatelessWidget {
  const _FavoriteHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 26,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accent50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.favorite, color: AppColors.accent500),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Favorit Saya',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '$count produk tersimpan untuk dipantau.',
                    style: const TextStyle(
                      color: AppColors.zinc500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteProductLayout extends StatelessWidget {
  const _FavoriteProductLayout({
    required this.products,
    required this.onOpenProduct,
    required this.onToggleFavorite,
  });

  final List<AuctionProduct> products;
  final ValueChanged<AuctionProduct> onOpenProduct;
  final ValueChanged<AuctionProduct> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1040
            ? 4
            : width >= 700
            ? 3
            : width >= 340
            ? 2
            : 1;

        if (columns == 1) {
          return Column(
            children: [
              for (final product in products) ...[
                AuctionProductCard(
                  product: product,
                  compact: true,
                  onFavoriteToggle: onToggleFavorite,
                  onTap: () => onOpenProduct(product),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 282,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return AuctionProductCard(
              product: product,
              compact: true,
              onFavoriteToggle: onToggleFavorite,
              onTap: () => onOpenProduct(product),
            );
          },
        );
      },
    );
  }
}
