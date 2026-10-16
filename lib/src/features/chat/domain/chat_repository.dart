import '../../../data/models/chat_message.dart';
import '../../../data/models/chat_thread.dart';

abstract class ChatRepository {
  Future<List<ChatThread>> threads();

  Future<ChatThread?> thread(int threadId);

  Future<ChatThread> startForProduct(int productId);

  Future<List<ChatMessage>> messages(int threadId);

  Future<ChatMessage> sendMessage(int threadId, String body);

  Future<void> markRead(int threadId);
}
