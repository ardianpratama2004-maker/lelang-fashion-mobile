import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/product_image.dart';
import '../../../data/models/chat_thread.dart';
import '../domain/chat_repository.dart';

/// Thread list screen with visibility-aware polling.
/// Stops polling while a request is in-flight, when the widget is
/// disposed, and when the app is pushed to background.
class ChatThreadListScreen extends StatefulWidget {
  const ChatThreadListScreen({required this.repository, super.key});

  final ChatRepository repository;

  @override
  State<ChatThreadListScreen> createState() => _ChatThreadListScreenState();
}

class _ChatThreadListScreenState extends State<ChatThreadListScreen>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 5);

  Timer? _pollTimer;
  List<ChatThread> _threads = const [];
  bool _loading = true;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitial();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      unawaited(_fetch());
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _fetch());
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    await _fetch(initial: true);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetch({bool initial = false}) async {
    if (_fetching) return;
    _fetching = true;
    try {
      final threads = await widget.repository.threads();
      if (mounted) setState(() => _threads = threads);
    } catch (error) {
      if (mounted && initial) showError(context, error.toString());
    } finally {
      _fetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Percakapan')),
      body: AppBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _threads.isEmpty
            ? const EmptyState(
                message: 'Belum ada percakapan. Buka detail produk lalu gunakan tombol Chat Admin.',
              )
            : RefreshIndicator(
                onRefresh: () => _fetch(initial: true),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
                  itemBuilder: (context, index) =>
                      _ChatThreadTile(thread: _threads[index]),
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemCount: _threads.length,
                ),
              ),
      ),
    );
  }
}

class _ChatThreadTile extends StatelessWidget {
  const _ChatThreadTile({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: EdgeInsets.zero,
      radius: 18,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/chat/${thread.id}'),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    child: ProductImage(
                      url: thread.productImageUrl,
                      height: 56,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              thread.productTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (thread.unread)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: AppColors.accent500,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thread.latestMessage?.body ?? 'Belum ada pesan.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            thread.isOpen
                                ? Icons.mark_chat_unread_outlined
                                : Icons.lock_outline,
                            size: 15,
                            color: thread.isOpen
                                ? AppColors.brand700
                                : AppColors.zinc500,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            thread.lastMessageAt == null
                                ? 'Percakapan baru'
                                : dateText(thread.lastMessageAt),
                            style: const TextStyle(
                              color: AppColors.zinc500,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
