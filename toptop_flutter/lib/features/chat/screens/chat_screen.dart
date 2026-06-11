import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';

/// Màn hình Chat chi tiết giữa 2 người dùng
/// Port từ ChatActivity.java trong Android project
class ChatScreen extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;

  const ChatScreen({
    super.key,
    required this.receiverId,
    this.receiverName = '',
    this.receiverAvatar = '',
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUid = ref.read(authStateProvider).valueOrNull?.uid;
    if (currentUid == null) return;

    ref.read(chatRepositoryProvider).sendMessage(
          senderId: currentUid,
          receiverId: widget.receiverId,
          message: text,
        );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(authStateProvider).valueOrNull?.uid;
    final isSystem = widget.receiverId == 'system_admin';

    // Xác định Room ID
    final roomId = currentUid != null
        ? ref.read(chatRepositoryProvider).getRoomId(currentUid, widget.receiverId)
        : '';

    // Theo dõi tin nhắn
    final messagesAsync = ref.watch(chatMessagesProvider(roomId));

    // Lấy thông tin thời gian thực của người nhận (nếu không phải system_admin)
    String displayUsername = widget.receiverName;
    String displayAvatar = widget.receiverAvatar;
    bool isOnline = false;

    if (!isSystem) {
      final profileAsync = ref.watch(userProfileStreamProvider(widget.receiverId));
      final onlineAsync = ref.watch(userOnlineStatusProvider(widget.receiverId));
      isOnline = onlineAsync.valueOrNull ?? false;

      if (profileAsync.valueOrNull != null) {
        displayUsername = profileAsync.valueOrNull!.username;
        displayAvatar = profileAsync.valueOrNull!.avatarUrl;
      }
    } else {
      displayUsername = 'Hệ thống TopTop';
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isSystem ? const Color(0xFFFE2C55).withValues(alpha: 0.1) : Colors.grey[800],
                  backgroundImage: displayAvatar.isNotEmpty ? NetworkImage(displayAvatar) : null,
                  child: displayAvatar.isEmpty
                      ? Icon(
                          isSystem ? Icons.verified_user_rounded : Icons.person,
                          color: isSystem ? const Color(0xFFFE2C55) : Colors.white,
                          size: 20,
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.backgroundColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayUsername.isNotEmpty ? displayUsername : 'Người dùng',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isSystem)
                    Text(
                      isOnline ? 'Đang hoạt động' : 'Ngoại tuyến',
                      style: TextStyle(
                        color: isOnline ? Colors.green : AppTheme.textHint,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Danh sách tin nhắn
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        isSystem
                            ? 'Không có thông báo hệ thống nào.'
                            : 'Hãy gửi tin nhắn để bắt đầu cuộc trò chuyện.',
                        style: const TextStyle(color: AppTheme.textHint, fontSize: 13),
                      ),
                    );
                  }

                  // Đảo ngược danh sách để hiển thị bằng ListView cuộn ngược
                  final reversedMessages = messages.reversed.toList();

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Cuộn từ dưới lên giúp tin nhắn mới tự động dính đáy
                    padding: const EdgeInsets.all(16),
                    itemCount: reversedMessages.length,
                    itemBuilder: (context, index) {
                      final msg = reversedMessages[index];
                      final isMsgMe = msg.senderId == currentUid;
                      return ChatBubble(
                        message: msg,
                        isMe: isMsgMe,
                        otherUserAvatar: displayAvatar,
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFE2C55)),
                  ),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Lỗi tải tin nhắn: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),

            // Thanh nhập tin nhắn
            if (isSystem)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  border: Border(
                    top: BorderSide(color: AppTheme.dividerColor, width: 0.5),
                  ),
                ),
                child: const Text(
                  'Bạn không thể phản hồi tin nhắn hệ thống này.',
                  style: TextStyle(color: AppTheme.textHint, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  border: Border(
                    top: BorderSide(color: AppTheme.dividerColor, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Gửi tin nhắn...',
                            hintStyle: TextStyle(color: AppTheme.textHint, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFFE2C55)),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
