// ignore_for_file: prefer_initializing_formals

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../core/constants/app_constants.dart';
import '../models/chat_message_model.dart';
import '../models/notification_model.dart';

/// Repository quản lý Chat, Presence & Notifications trên Realtime Database & Firestore
/// Port từ ChatActivity.java, InboxFragment.java, InboxActivity.java và GlobalVariable.java
class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _database;

  ChatRepository({
    required FirebaseFirestore firestore,
    required FirebaseDatabase database,
  })  : _firestore = firestore,
        _database = database;

  /// Tạo Room ID duy nhất từ hai user ID (sắp xếp tăng dần theo bảng chữ cái)
  String getRoomId(String id1, String id2) {
    return (id1.compareTo(id2) < 0) ? '${id1}_$id2' : '${id2}_$id1';
  }

  /// Gửi tin nhắn và cập nhật danh sách chat + thông báo
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final roomId = getRoomId(senderId, receiverId);

    // 1. Đẩy tin nhắn vào node Chats/{roomId}
    final messagesRef = _database.ref('Chats').child(roomId);
    final msgKey = messagesRef.push().key;
    if (msgKey == null) return;

    final chatMessage = ChatMessageModel(
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      type: 'text',
    );

    // Chuẩn bị cập nhật đa điểm (multi-path updates)
    final Map<String, Map<String, dynamic>> updates = {};

    // Ghi tin nhắn
    updates['/Chats/$roomId/$msgKey'] = chatMessage.toMap();

    // Cập nhật ChatList cho người gửi
    updates['/ChatList/$senderId/$receiverId'] = {
      'id': receiverId,
      'lastMessage': message,
      'timestamp': timestamp,
    };

    // Cập nhật ChatList cho người nhận
    updates['/ChatList/$receiverId/$senderId'] = {
      'id': senderId,
      'lastMessage': message,
      'timestamp': timestamp,
    };

    // Thực hiện cập nhật đồng thời
    await _database.ref().update(updates);

    // 2. Gửi thông báo đến người nhận thông qua node Notifications/{receiverId}
    // Lấy username của người gửi từ Firestore
    try {
      final doc = await _firestore.collection(AppConstants.profilesCollection).doc(senderId).get();
      final senderUsername = doc.exists ? (doc.data()?['username'] as String? ?? 'Ai đó') : 'Ai đó';

      final notifRef = _database.ref('Notifications').child(receiverId).push();
      await notifRef.set({
        'fromUsername': senderUsername,
        'action': AppConstants.actionChat,
        'timestamp': timestamp,
      });
    } catch (_) {
      // Bỏ qua lỗi thông báo để không ngắt luồng gửi tin nhắn
    }
  }

  /// Stream danh sách tin nhắn trong một cuộc trò chuyện
  Stream<List<ChatMessageModel>> watchMessages(String roomId) {
    return _database.ref('Chats').child(roomId).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final List<ChatMessageModel> messages = [];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, val) {
        if (val is Map) {
          messages.add(ChatMessageModel.fromMap(val));
        }
      });

      // Sắp xếp theo timestamp tăng dần để hiển thị từ cũ đến mới
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  /// Stream danh sách cuộc trò chuyện của một user từ Realtime Database
  Stream<List<Map<String, dynamic>>> watchChatList(String userId) {
    return _database.ref('ChatList').child(userId).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final List<Map<String, dynamic>> list = [];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, val) {
        if (val is Map) {
          final timestamp = val['timestamp'] ?? val['lastTimestamp'] ?? 0;
          list.add({
            'userId': key as String,
            'lastMessage': val['lastMessage'] as String? ?? '',
            'timestamp': (timestamp as num).toInt(),
          });
        }
      });

      // Sắp xếp cuộc trò chuyện có tin nhắn mới nhất lên đầu
      list.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      return list;
    });
  }

  /// Cập nhật trạng thái hoạt động (presence) của user hiện tại
  Future<void> updatePresence(String userId, bool online) async {
    final statusRef = _database.ref('status').child(userId);

    final Map<String, dynamic> offlineStatus = {
      'online': false,
      'lastActive': ServerValue.timestamp,
    };

    if (online) {
      final Map<String, dynamic> onlineStatus = {
        'online': true,
        'lastActive': ServerValue.timestamp,
      };

      // Tự động set offline khi ngắt kết nối
      await statusRef.onDisconnect().set(offlineStatus);
      await statusRef.set(onlineStatus);
    } else {
      await statusRef.set(offlineStatus);
    }
  }

  /// Khởi tạo listener tự động đồng bộ kết nối mạng
  void setupPresenceAutomation(String userId) {
    // Theo dõi trạng thái kết nối mạng của Firebase
    _database.ref('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (connected) {
        updatePresence(userId, true);
      }
    });
  }

  /// Stream kiểm tra online status của một user cụ thể
  Stream<bool> watchUserOnlineStatus(String userId) {
    return _database.ref('status').child(userId).child('online').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  /// Stream danh sách thông báo của user từ Realtime Database
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _database.ref('Notifications').child(userId).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final List<NotificationModel> list = [];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, val) {
        if (val is Map) {
          list.add(NotificationModel.fromMap(val, id: key as String));
        }
      });

      // Sắp xếp thông báo mới nhất lên đầu
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }
}
