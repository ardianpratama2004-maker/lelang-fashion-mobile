import '../../../data/api/api_client.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/chat_thread.dart';
import '../domain/chat_repository.dart';

class ApiChatRepository implements ChatRepository {
  ApiChatRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ChatThread>> threads() {
    return _api.chatThreads();
  }

  @override
  Future<ChatThread?> thread(int threadId) {
    return _api.chatThread(threadId);
  }

  @override
  Future<ChatThread> startForProduct(int productId) {
    return _api.startProductChat(productId);
  }

  @override
  Future<List<ChatMessage>> messages(int threadId) {
    return _api.chatMessages(threadId);
  }

  @override
  Future<ChatMessage> sendMessage(int threadId, String body) {
    return _api.sendChatMessage(threadId, body);
  }

  @override
  Future<void> markRead(int threadId) async {
    await _api.markChatRead(threadId);
  }
}
