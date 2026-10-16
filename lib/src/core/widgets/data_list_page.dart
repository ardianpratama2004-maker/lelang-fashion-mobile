import 'package:flutter/material.dart';

import 'app_surface.dart';
import 'empty_state.dart';
import 'error_state.dart';

class DataListPage<T> extends StatelessWidget {
  const DataListPage({
    required this.title,
    required this.future,
    required this.onRefresh,
    required this.emptyMessage,
    required this.itemBuilder,
    super.key,
  });

  final String title;
  final Future<List<T>> future;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
        children: [
          SectionHeader(title: title),
          const SizedBox(height: 10),
          FutureBuilder<List<T>>(
            future: future,
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
                  onRetry: onRefresh,
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) return EmptyState(message: emptyMessage);
              return Column(
                children: [
                  for (final item in items) ...[
                    itemBuilder(item),
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
