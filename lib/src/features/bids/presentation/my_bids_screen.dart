import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/data_list_page.dart';
import '../../../data/models/bid_record.dart';
import '../domain/bid_repository.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({required this.repository, super.key});

  final BidRepository repository;

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  late Future<List<BidRecord>> _future = widget.repository.myBids();

  Future<void> _refresh() async {
    setState(() => _future = widget.repository.myBids());
  }

  @override
  Widget build(BuildContext context) {
    return DataListPage<BidRecord>(
      title: 'Bid Saya',
      future: _future,
      onRefresh: _refresh,
      emptyMessage: 'Belum ada bid yang dikirim.',
      itemBuilder: (bid) => GlassSurface(
        padding: EdgeInsets.zero,
        radius: 22,
        shadow: false,
        child: ListTile(
          title: Text(bid.productTitle ?? '-'),
          subtitle: Text(dateText(bid.createdAt)),
          trailing: Text(
            money(bid.amount),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
