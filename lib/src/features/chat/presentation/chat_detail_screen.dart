import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/chat_thread.dart';
import '../domain/chat_repository.dart';

/// Chat detail screen with visibility-aware polling.
///
/// Design goals:
/// - User-initiated actions (typing, sending) never compete with polling
///   because polling is skipped while a send is in-flight.
/// - Messages are de-duplicated by id so optimistic local appends are not
///   overwritten nor duplicated by the next poll.
/// - Polling pauses when the app enters background (lifecycle) and resumes
///   on foreground, which prevents wasted requests and battery drain.
class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    required this.repository,
    required this.threadId,
    super.key,
  });

  final ChatRepository repository;
  final int threadId;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 3);

  final _body = TextEditingController();
  final _scrollController = ScrollController();

  Timer? _pollTimer;
  ChatThread? _thread;
  final Map<int, ChatMessage> _messagesById = <int, ChatMessage>{};
  List<ChatMessage> _messagesSorted = const [];
  bool _loading = true;
  bool _sending = false;
  bool _polling = false;

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
    _body.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      unawaited(_fetch());
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _fetch());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    await _fetch(initial: true);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetch({bool initial = false}) async {
    // Never fetch while the user is sending. Keeps optimistic state stable
    // and avoids overlapping network requests on the same resource.
    if (_sending || _polling) return;
    _polling = true;
    try {
      final results = await Future.wait([
        widget.repository.thread(widget.threadId),
        widget.repository.messages(widget.threadId),
      ]);
      if (!mounted) return;

      final thread = results[0] as ChatThread?;
      final remote = results[1] as List<ChatMessage>;

      setState(() {
        if (thread != null) _thread = thread;
        _mergeRemoteMessages(remote);
      });

      if (thread?.unread ?? false) {
        unawaited(widget.repository.markRead(widget.threadId));
      }
    } catch (error) {
      if (mounted && initial) showError(context, error.toString());
    } finally {
      _polling = false;
    }
  }

  void _mergeRemoteMessages(List<ChatMessage> remote) {
    for (final message in remote) {
      _messagesById[message.id] = message;
    }
    _rebuildSortedMessages();
  }

  void _rebuildSortedMessages() {
    final list = _messagesById.values.toList()
      ..sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        if (aTime != null && bTime != null) {
          final cmp = aTime.compareTo(bTime);
          if (cmp != 0) return cmp;
        }
        return a.id.compareTo(b.id);
      });
    _messagesSorted = list;
  }

  Future<void> _send() async {
    final body = _body.text.trim();
    if (body.isEmpty) return;

    setState(() => _sending = true);
    try {
      final message = await widget.repository.sendMessage(
        widget.threadId,
        body,
      );
      _body.clear();
      if (!mounted) return;
      setState(() {
        _messagesById[message.id] = message;
        _rebuildSortedMessages();
      });
      _scrollToBottomSoon();
      unawaited(widget.repository.markRead(widget.threadId));
    } catch (error) {
      if (mounted) showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottomSoon() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat Admin'),
            if (thread != null)
              Text(
                thread.productTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.zinc500,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
      body: AppBackground(
        child: _loading && _messagesSorted.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (thread != null) _ThreadHeader(thread: thread),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _fetch(initial: true),
                      child: _buildMessageList(),
                    ),
                  ),
                  if (thread?.isOpen ?? true)
                    SafeArea(
                      top: false,
                      child: GlassSurface(
                        radius: 18,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _body,
                                minLines: 1,
                                maxLines: 4,
                                enabled: !_sending,
                                scrollPadding: const EdgeInsets.only(
                                  bottom: 120,
                                ),
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                  hintText: 'Tulis pesan ke admin...',
                                  prefixIcon: Icon(Icons.chat_bubble_outline),
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            FilledButton(
                              onPressed: _sending ? null : _send,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(46, 46),
                                padding: EdgeInsets.zero,
                              ),
                              child: _sending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messagesSorted.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 120),
            child: Text(
              'Belum ada pesan. Tulis pesan pertama untuk menghubungi admin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.zinc500),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      itemCount: _messagesSorted.length,
      itemBuilder: (context, index) {
        final message = _messagesSorted[index];
        return _MessageBubble(message: message);
      },
    );
  }
}

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GlassSurface(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        radius: 0,
        shadow: false,
        child: Row(
          children: [
            Icon(
              thread.isOpen ? Icons.support_agent : Icons.lock_outline,
              color: thread.isOpen ? AppColors.brand700 : AppColors.zinc500,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                thread.isOpen
                    ? 'Admin akan membantu kendala lelang produk ini.'
                    : 'Percakapan ini sudah ditutup admin.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final fromAdmin = message.fromAdmin;
    final color = fromAdmin ? Colors.white : AppColors.brand800;
    final textColor = fromAdmin ? AppColors.zinc950 : Colors.white;

    return Align(
      alignment: fromAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14).copyWith(
            bottomLeft: fromAdmin ? const Radius.circular(4) : null,
            bottomRight: fromAdmin ? null : const Radius.circular(4),
          ),
          border: fromAdmin ? Border.all(color: AppColors.zinc200) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fromAdmin ? 'Admin' : 'Kamu',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(message.body, style: TextStyle(color: textColor)),
            if (message.createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                dateText(message.createdAt),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.58),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
