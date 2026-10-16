import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../data/models/auction_product.dart';
import '../domain/auction_repository.dart';
import 'widgets/auction_product_card.dart';

class AuctionListScreen extends StatefulWidget {
  const AuctionListScreen({required this.repository, super.key});

  final AuctionRepository repository;

  @override
  State<AuctionListScreen> createState() => _AuctionListScreenState();
}

class _AuctionListScreenState extends State<AuctionListScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final List<AuctionProduct> _products = [];
  Timer? _searchDebounce;
  String? _status;
  String _query = '';
  int _page = 1;
  bool _hasMore = true;
  bool _loadingInitial = true;
  bool _loadingMore = false;
  Object? _error;
  final Set<int> _favoriteBusy = {};

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _reload();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scroll.dispose();
    _search.dispose();
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
      final result = await widget.repository.productPage(
        status: _status,
        query: _query,
        page: page,
      );
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

    final next = !product.isFavorited;
    setState(() {
      _favoriteBusy.add(product.id);
      _replaceProduct(product.copyWith(isFavorited: next));
    });

    try {
      final updated = next
          ? await widget.repository.favoriteProduct(product.id)
          : await widget.repository.unfavoriteProduct(product.id);
      if (!mounted) return;
      setState(() => _replaceProduct(updated));
    } catch (error) {
      if (mounted) {
        setState(() => _replaceProduct(product));
        showError(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _favoriteBusy.remove(product.id));
      }
    }
  }

  void _replaceProduct(AuctionProduct product) {
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index >= 0) _products[index] = product;
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), _reload);
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _search.clear();
    if (_query.isEmpty) return;

    setState(() => _query = '');
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
        children: [
          const _AuctionHomeHeader(),
          const SizedBox(height: 10),
          GlassSurface(
            padding: const EdgeInsets.all(12),
            radius: 20,
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: _query.isEmpty ? _reload : _clearSearch,
                      icon: Icon(
                        _query.isEmpty ? Icons.arrow_forward : Icons.close,
                      ),
                      tooltip: _query.isEmpty ? 'Cari' : 'Bersihkan',
                    ),
                    hintText: 'Cari jaket, sepatu, tas...',
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => _reload(),
                ),
                const SizedBox(height: 9),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _AuctionFilterChip(
                        label: 'Semua',
                        selected: _status == null,
                        onTap: () {
                          _status = null;
                          _reload();
                        },
                      ),
                      for (final item in const [
                        'active',
                        'scheduled',
                        'closed',
                      ])
                        _AuctionFilterChip(
                          label: statusLabel(item),
                          selected: _status == item,
                          onTap: () {
                            _status = item;
                            _reload();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingInitial)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && _products.isEmpty)
            ErrorState(message: _error.toString(), onRetry: _reload)
          else if (_products.isEmpty)
            const EmptyState(message: 'Belum ada produk lelang.')
          else
            _AuctionProductLayout(
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
          else if (_error != null && _products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: OutlinedButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba muat lagi'),
              ),
            )
          else if (!_hasMore && _products.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Center(
                child: Text(
                  'Semua produk sudah tampil.',
                  style: TextStyle(
                    color: AppColors.zinc500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuctionProductLayout extends StatelessWidget {
  const _AuctionProductLayout({
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
            mainAxisExtent: 286,
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

class _AuctionHomeHeader extends StatelessWidget {
  const _AuctionHomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand950, AppColors.brand800],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand950.withValues(alpha: 0.13),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            bottom: -56,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.brand700.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 10,
            child: Icon(
              Icons.gavel_rounded,
              size: 82,
              color: Colors.white.withValues(alpha: 0.11),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Image.asset(AppAssets.logo),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lelang Fashion',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Koleksi pilihan, bid terbaikmu.',
                          style: TextStyle(
                            color: AppColors.brand100,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: () => context.push('/favorit'),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Temukan barang\nincaranmu',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: Colors.white, fontSize: 24, height: 1.08),
              ),
              const SizedBox(height: 6),
              const Text(
                'Jelajahi lelang dan ajukan bid.',
                style: TextStyle(
                  color: AppColors.brand100,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuctionFilterChip extends StatelessWidget {
  const _AuctionFilterChip({
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
