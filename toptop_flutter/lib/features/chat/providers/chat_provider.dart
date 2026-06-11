import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../models/chat_message_model.dart';
import '../models/notification_model.dart';
import '../repositories/chat_repository.dart';

/// Provider cho ChatRepository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    firestore: ref.watch(firestoreProvider),
    database: ref.watch(realtimeDbProvider),
  );
});

/// StreamProvider theo dõi danh sách tin nhắn theo Room ID
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessageModel>, String>((ref, roomId) {
  return ref.watch(chatRepositoryProvider).watchMessages(roomId);
});

/// StreamProvider theo dõi danh sách các cuộc trò chuyện của user hiện tại
final chatConversationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUid = authState.valueOrNull?.uid;

  if (currentUid == null) {
    return Stream.value([]);
  }

  return ref.watch(chatRepositoryProvider).watchChatList(currentUid);
});

/// StreamProvider theo dõi trạng thái online của một user cụ thể
final userOnlineStatusProvider =
    StreamProvider.family<bool, String>((ref, userId) {
  return ref.watch(chatRepositoryProvider).watchUserOnlineStatus(userId);
});

/// StreamProvider theo dõi danh sách thông báo của user hiện tại
final notificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUid = authState.valueOrNull?.uid;

  if (currentUid == null) {
    return Stream.value([]);
  }

  return ref.watch(chatRepositoryProvider).watchNotifications(currentUid);
});

/// StreamProvider theo dõi danh sách User ID đang Online trong danh sách chat
final activeUsersProvider = StreamProvider<List<String>>((ref) {
  final conversations = ref.watch(chatConversationsProvider).valueOrNull ?? [];
  if (conversations.isEmpty) return Stream.value([]);

  final database = ref.watch(realtimeDbProvider);
  final controller = AsyncStreamController<List<String>>();
  final Map<String, bool> onlineStates = {};
  final List<dynamic> subscriptions = [];

  void emitCurrentOnline() {
    final onlineIds = conversations
        .map((c) => c['userId'] as String)
        .where((uid) => onlineStates[uid] == true)
        .toList();
    if (!controller.isClosed) {
      controller.add(onlineIds);
    }
  }

  for (final conv in conversations) {
    final uid = conv['userId'] as String;
    if (uid == 'system_admin') continue;
    final sub = database.ref('status').child(uid).child('online').onValue.listen((event) {
      final isOnline = event.snapshot.value as bool? ?? false;
      onlineStates[uid] = isOnline;
      emitCurrentOnline();
    });
    subscriptions.add(sub);
  }

  // Phát tín hiệu ban đầu
  emitCurrentOnline();

  ref.onDispose(() {
    for (final sub in subscriptions) {
      sub.cancel();
    }
    controller.close();
  });

  return controller.stream;
});

class AsyncStreamController<T> {
  final _controller = StreamController<T>.broadcast();
  bool get isClosed => _controller.isClosed;
  Stream<T> get stream => _controller.stream;

  void add(T event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void close() {
    _controller.close();
  }
}

