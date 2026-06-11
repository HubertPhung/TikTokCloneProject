import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../models/chat_message_model.dart';

/// Widget hiển thị bong bóng tin nhắn (trái/phải)
/// Port từ ChatAdapter.java trong Android project
class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final String otherUserAvatar;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.otherUserAvatar,
  });

  /// Hiển thị Dialog kháng cáo
  /// Port từ ChatAdapter.showAppealDialog()
  void _showAppealDialog(BuildContext context, String reportId) {
    final controller = TextEditingController();
    final docRef = FirebaseFirestore.instance.collection(AppConstants.reportsCollection).doc(reportId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Phản ánh báo cáo',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nhập nội dung phản ánh của bạn...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Nhập nội dung phản ánh...',
                hintStyle: TextStyle(color: AppTheme.textHint),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFE2C55)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE2C55),
            ),
            onPressed: () {
              final content = controller.text.trim();
              if (content.isNotEmpty) {
                docRef.update({'appeal': content}).then((_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã gửi phản ánh thành công!')),
                    );
                    Navigator.pop(context);
                  }
                }).catchError((error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $error')),
                    );
                  }
                });
              }
            },
            child: const Text('Gửi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Phân tích tin nhắn và sinh RichText cho links
  /// Port từ ChatAdapter.setupAppealMessage() và ChatAdapter.setupMessageText()
  Widget _buildMessageContent(BuildContext context) {
    final text = message.message;

    // 1. Trường hợp tin nhắn kháng cáo hệ thống: chứa [APPEAL:reportId]
    if (text.contains('[APPEAL:') && text.endsWith(']')) {
      final appealIdx = text.indexOf(' [APPEAL:');
      final displayText = text.substring(0, appealIdx);
      final reportId = text.substring(text.indexOf(':') + 1, text.length - 1);

      final clickKeyword = 'nhấn vào đây';
      final keywordIdx = displayText.indexOf(clickKeyword);

      if (keywordIdx != -1) {
        final preText = displayText.substring(0, keywordIdx);
        final postText = displayText.substring(keywordIdx + clickKeyword.length);

        return RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            children: [
              TextSpan(text: preText),
              TextSpan(
                text: clickKeyword,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    _showAppealDialog(context, reportId);
                  },
              ),
              TextSpan(text: postText),
            ],
          ),
        );
      }

      return Text(
        displayText,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );
    }

    // 2. Trường hợp tin nhắn chia sẻ video: chứa URL trang share
    const sharePrefix = 'https://hubertphung.github.io/toptop-share-page/?id=';
    if (text.contains(sharePrefix)) {
      final startIdx = text.indexOf(sharePrefix);
      int endIdx = text.indexOf(' ', startIdx);
      if (endIdx == -1) {
        endIdx = text.length;
      }
      final videoId = text.substring(startIdx + sharePrefix.length, endIdx).trim();

      final preText = text.substring(0, startIdx);
      final postText = text.substring(endIdx);

      return RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          children: [
            if (preText.isNotEmpty) TextSpan(text: preText),
            TextSpan(
              text: '🎥 Xem video chia sẻ: $videoId',
              style: const TextStyle(
                color: Colors.lightBlueAccent,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  context.push('/video/$videoId');
                },
            ),
            if (postText.isNotEmpty) TextSpan(text: postText),
          ],
        ),
      );
    }

    // 3. Tin nhắn văn bản thông thường
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Hiển thị Avatar của đối phương bên trái tin nhắn gửi đến
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[800],
              backgroundImage: otherUserAvatar.isNotEmpty ? NetworkImage(otherUserAvatar) : null,
              child: otherUserAvatar.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 8),
          ],

          // Bong bóng tin nhắn
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFFE2C55) : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: _buildMessageContent(context),
            ),
          ),
          if (isMe) const SizedBox(width: 8), // Padding bên phải cho tin nhắn của tôi
        ],
      ),
    );
  }
}
