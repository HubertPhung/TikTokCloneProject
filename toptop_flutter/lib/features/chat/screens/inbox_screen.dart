import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/active_users_row.dart';

/// Màn hình Hộp thư (Danh sách Chat & Active Users)
/// Port từ InboxFragment.java trong Android project
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  /// Tính toán thời gian tương đối
  String _formatTime(int timestamp) {
    if (timestamp <= 0) return '';
    final difference = DateTime.now().millisecondsSinceEpoch - timestamp;
    final diffMinutes = difference ~/ (1000 * 60);
    final diffHours = difference ~/ (1000 * 60 * 60);
    final diffDays = difference ~/ (1000 * 60 * 60 * 24);

    if (diffMinutes <= 60) {
      return '${diffMinutes}m';
    } else if (diffHours <= 24) {
      return '${diffHours}h';
    } else {
      return '${diffDays}d';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(chatConversationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          'Hộp thư',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Nút xem thông báo tương tác (Like, Comment, Follow) - Mở InboxActivity tương ứng
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh danh sách người dùng Online ngang
          const ActiveUsersRow(),

          // Danh sách các cuộc hội thoại dọc
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                if (conversations.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mail_outline_rounded,
                          size: 64,
                          color: AppTheme.textHint,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Hộp thư trống',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Bắt đầu nhắn tin với bạn bè của bạn',
                          style: TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: conversations.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 76,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final otherUserId = conv['userId'] as String;
                    final lastMsg = conv['lastMessage'] as String? ?? 'Chưa có tin nhắn';
                    final timestamp = conv['timestamp'] as int;

                    return _ConversationTile(
                      otherUserId: otherUserId,
                      lastMessage: lastMsg,
                      timestamp: timestamp,
                      formatTime: _formatTime(timestamp),
                    );
                  },
                );
              },
              loading: () => const ShimmerInboxList(),
              error: (error, _) => Center(
                child: Text(
                  'Lỗi tải tin nhắn: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final String otherUserId;
  final String lastMessage;
  final int timestamp;
  final String formatTime;

  const _ConversationTile({
    required this.otherUserId,
    required this.lastMessage,
    required this.timestamp,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSystem = otherUserId == 'system_admin';

    if (isSystem) {
      return _buildTile(
        context,
        username: 'Hệ thống TopTop',
        avatarUrl: '',
        isOnline: false,
        isSystem: true,
      );
    }

    final profileAsync = ref.watch(userProfileStreamProvider(otherUserId));
    final isOnlineAsync = ref.watch(userOnlineStatusProvider(otherUserId));
    final isOnline = isOnlineAsync.valueOrNull ?? false;

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        return _buildTile(
          context,
          username: profile.username.isNotEmpty ? profile.username : 'User',
          avatarUrl: profile.avatarUrl,
          isOnline: isOnline,
          isSystem: false,
        );
      },
      loading: () => const SizedBox(height: 72),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String username,
    required String avatarUrl,
    required bool isOnline,
    required bool isSystem,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: isSystem ? const Color(0xFFFE2C55).withValues(alpha: 0.1) : Colors.grey[800],
            backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl, maxWidth: 100) : null,
            child: avatarUrl.isEmpty
                ? Icon(
                    isSystem ? Icons.verified_user_rounded : Icons.person,
                    color: isSystem ? const Color(0xFFFE2C55) : Colors.white,
                    size: 28,
                  )
                : null,
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: RepaintBoundary(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.backgroundColor,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        username,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
      trailing: Text(
        formatTime,
        style: const TextStyle(
          color: AppTheme.textHint,
          fontSize: 11,
        ),
      ),
      onTap: () {
        context.push(
          '/chat/$otherUserId?name=${Uri.encodeComponent(username)}&avatar=${Uri.encodeComponent(avatarUrl)}',
        );
      },
    );
  }
}
