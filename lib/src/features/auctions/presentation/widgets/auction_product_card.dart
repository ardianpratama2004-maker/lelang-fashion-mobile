import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../../data/models/auction_product.dart';

class AuctionProductCard extends StatelessWidget {
  const AuctionProductCard({
    required this.product,
    required this.onTap,
    this.compact = false,
    this.onFavoriteToggle,
    super.key,
  });

  final AuctionProduct product;
  final VoidCallback onTap;
  final bool compact;
  final ValueChanged<AuctionProduct>? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final currentPrice = product.currentHighestBid == 0
        ? product.startingPrice
        : product.currentHighestBid;

    return GlassSurface(
      padding: EdgeInsets.zero,
      radius: 20,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ProductImage(
                    url: product.imageUrl,
                    height: compact ? 116 : 174,
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _statusColor(product.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel(product.status),
                            style: const TextStyle(
                              color: AppColors.zinc950,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconBubble(
                      icon: product.isFavorited
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 34,
                      iconSize: 20,
                      foregroundColor: product.isFavorited
                          ? AppColors.accent500
                          : AppColors.zinc500,
                      onTap: onFavoriteToggle == null
                          ? null
                          : () => onFavoriteToggle!(product),
                      tooltip: product.isFavorited
                          ? 'Hapus dari favorit'
                          : 'Tambah ke favorit',
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(compact ? 10 : 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900, height: 1.12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [product.category, product.brand]
                          .where((item) => item != null && item.isNotEmpty)
                          .join(' - '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.zinc500,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Harga tertinggi',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.zinc500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      money(currentPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.accent700,
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Selesai',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.zinc500),
                              ),
                              Text(
                                dateText(product.endsAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 42,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.accent50,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.gavel,
                            color: AppColors.accent700,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'active' => AppColors.brand500,
      'scheduled' => AppColors.info700,
      'closed' => AppColors.zinc500,
      _ => AppColors.accent500,
    };
  }
}
