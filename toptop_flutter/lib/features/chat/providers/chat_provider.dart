import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// StreamProvider theo dõi trạng thái "đang nhập" trong một room
/// Key = "$roomId|$otherUserId"
final typingStatusProvider =
    StreamProvider.family<bool, String>((ref, key) {
  final parts = key.split('|');
  if (parts.length != 2) return Stream.value(false);
  final roomId = parts[0];
  final otherUserId = parts[1];
  return ref.watch(chatRepositoryProvider).watchTyping(roomId, otherUserId);
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

/// Lớp hỗ trợ so sánh sâu danh sách ID để tối ưu hóa Riverpod select
class UserIdsList {
  final List<String> ids;
  UserIdsList(this.ids);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserIdsList &&
          const DeepCollectionEquality().equals(ids, other.ids);

  @override
  int get hashCode => const DeepCollectionEquality().hash(ids);
}

/// Provider trích xuất danh sách User ID từ các cuộc trò chuyện và ngăn chặn rebuild thừa
final chatUserIdsProvider = Provider<List<String>>((ref) {
  final userIdsList = ref.watch(chatConversationsProvider.select((asyncVal) {
    final ids = asyncVal.maybeWhen(
      data: (list) => list.map((c) => c['userId'] as String).toList(),
      orElse: () => const <String>[],
    );
    return UserIdsList(ids);
  }));
  return userIdsList.ids;
});

/// StreamProvider theo dõi danh sách User ID đang Online trong danh sách chat
final activeUsersProvider = StreamProvider<List<String>>((ref) {
  final userIds = ref.watch(chatUserIdsProvider);
  if (userIds.isEmpty) return Stream.value([]);

  final database = ref.watch(realtimeDbProvider);
  final controller = AsyncStreamController<List<String>>();
  final Map<String, bool> onlineStates = {};
  final List<dynamic> subscriptions = [];

  void emitCurrentOnline() {
    final onlineIds = userIds
        .where((uid) => onlineStates[uid] == true)
        .toList();
    if (!controller.isClosed) {
      controller.add(onlineIds);
    }
  }

  for (final uid in userIds) {
    if (uid == 'system_admin') continue;
    final sub = database.ref('status').child(uid).child('online').onValue.listen(
      (event) {
        final val = event.snapshot.value;
        final bool isOnline;
        if (val is bool) {
          isOnline = val;
        } else if (val is String) {
          isOnline = val.toLowerCase() == 'true';
        } else if (val is num) {
          isOnline = val == 1;
        } else {
          isOnline = false;
        }
        onlineStates[uid] = isOnline;
        emitCurrentOnline();
      },
      onError: (error) {
        debugPrint("Error listening to online status of $uid: $error");
        onlineStates[uid] = false;
        emitCurrentOnline();
      },
    );
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

/// Provider quản lý timestamp thời điểm cuối cùng người dùng xem thông báo
final lastReadNotificationTimestampProvider = StateNotifierProvider<LastReadTimestampNotifier, int>((ref) {
  return LastReadTimestampNotifier();
});

class LastReadTimestampNotifier extends StateNotifier<int> {
  LastReadTimestampNotifier() : super(0) {
    _load();
  }

  static const _key = 'last_read_notification_timestamp';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getInt(_key) ?? 0;
    } catch (_) {}
  }

  Future<void> updateTimestamp() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, now);
      state = now;
    } catch (_) {}
  }
}

/// Provider tự động quản lý sự hiện diện (Presence) của người dùng hiện tại
final currentUserPresenceProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return;

  final database = ref.watch(realtimeDbProvider);
  final chatRepo = ref.watch(chatRepositoryProvider);
  final uid = user.uid;

  // Đặt trạng thái online ban đầu
  chatRepo.updatePresence(uid, true);

  // Lắng nghe tự động trạng thái kết nối mạng của Firebase
  final sub = database.ref('.info/connected').onValue.listen(
    (event) {
      try {
        final connected = event.snapshot.value as bool? ?? false;
        if (connected) {
          chatRepo.updatePresence(uid, true);
        }
      } catch (e) {
        debugPrint("Error in presence connection listener: $e");
      }
    },
    onError: (e) {
      debugPrint("Presence connection stream error: $e");
    },
  );

  ref.onDispose(() {
    sub.cancel();
    // Đặt trạng thái offline khi người dùng logout hoặc ứng dụng dispose
    chatRepo.updatePresence(uid, false);
  });
});

