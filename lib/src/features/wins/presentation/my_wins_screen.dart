import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/data_list_page.dart';
import '../../../core/widgets/product_image.dart';
import '../../../data/models/auction_product.dart';
import '../domain/win_repository.dart';

class MyWinsScreen extends StatefulWidget {
  const MyWinsScreen({required this.repository, super.key});

  final WinRepository repository;

  @override
  State<MyWinsScreen> createState() => _MyWinsScreenState();
}

class _MyWinsScreenState extends State<MyWinsScreen> {
  late Future<List<AuctionProduct>> _future = widget.repository.myWins();

  Future<void> _refresh() async {
    setState(() => _future = widget.repository.myWins());
  }

  @override
  Widget build(BuildContext context) {
    return DataListPage<AuctionProduct>(
      title: 'Lelang Dimenangkan',
      future: _future,
      onRefresh: _refresh,
      emptyMessage: 'Belum ada lelang yang dimenangkan.',
      itemBuilder: (product) => GlassSurface(
        padding: EdgeInsets.zero,
        radius: 22,
        shadow: false,
        child: ListTile(
          leading: SizedBox(
            width: 52,
            height: 52,
            child: ProductImage(url: product.imageUrl, height: 52),
          ),
          title: Text(product.title),
          subtitle: Text('Ditutup ${dateText(product.closedAt)}'),
          trailing: Text(
            money(product.currentHighestBid),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
