import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/video_model.dart';
import '../providers/video_provider.dart';
import '../../comments/widgets/comment_bottom_sheet.dart';

/// Sidebar chứa các nút tương tác (Avatar, Like, Bình luận, Chia sẻ, Tắt/Bật âm)
/// Port từ VideoAdapter.VideoViewHolder (imvLike, imvComment, imvAvatar, etc.)
class VideoActionBar extends ConsumerWidget {
  final VideoModel video;

  const VideoActionBar({
    super.key,
    required this.video,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      right: 12,
      bottom: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Tác giả Avatar
          Consumer(
            builder: (context, ref, child) {
              final currentUser = ref.watch(currentUserProvider);
              final authorProfile = ref.watch(videoAuthorProfileProvider(video.authorId)).valueOrNull;
              final avatarUrl = authorProfile?.avatarUrl ?? '';

              return GestureDetector(
                onTap: () {
                  if (currentUser != null && currentUser.uid == video.authorId) {
                    context.go('/profile');
                  } else {
                    context.push('/user/${video.authorId}');
                  }
                },
                child: RepaintBoundary(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: avatarUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 100, // Tối ưu kích thước lưu cache bộ nhớ
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[850],
                                    child: const Icon(Icons.person, color: Colors.white),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[850],
                                    child: const Icon(Icons.person, color: Colors.white),
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/default_avatar.png', // Fallback
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey[850],
                                    child: const Icon(Icons.person, color: Colors.white),
                                  ),
                                ),
                        ),
                      ),
                      // Nút Follow mini giống TikTok
                      if (currentUser == null || currentUser.uid != video.authorId)
                        Positioned(
                          bottom: -6,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 2. Nút Thích (Like)
          Consumer(
            builder: (context, ref, child) {
              final currentUser = ref.watch(currentUserProvider);
              final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;
              final likesState = ref.watch(videoLikesStateProvider(video.videoId));
              final likesCount = likesState.valueOrNull?['count'] as int? ?? video.totalLikes;
              final likedUsers = likesState.valueOrNull?['users'] as Map<String, dynamic>? ?? {};
              final isLiked = currentUser != null && likedUsers[currentUser.uid] == true;

              return _buildActionButton(
                icon: Icon(
                  Icons.favorite,
                  color: isLiked ? AppTheme.primaryColor : Colors.white,
                  size: 36,
                ),
                label: _formatCount(likesCount),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng đăng nhập để thích video!')),
                    );
                    context.go('/auth');
                    return;
                  }
                  final username = userProfile?.username ?? currentUser.email?.split('@')[0] ?? '';
                  await ref.read(videoRepositoryProvider).toggleLike(
                        videoId: video.videoId,
                        authorId: video.authorId,
                        currentUid: currentUser.uid,
                        isLiked: !isLiked,
                        currentUsername: username,
                      );
                },
              );
            },
          ),
          const SizedBox(height: 18),

          // 3. Nút Bình luận
          Consumer(
            builder: (context, ref, child) {
              final currentUser = ref.watch(currentUserProvider);
              final commentsCount = ref.watch(videoCommentsCountProvider(video.videoId)).valueOrNull ?? video.totalComments;

              return _buildActionButton(
                icon: const Icon(
                  Icons.comment,
                  color: Colors.white,
                  size: 34,
                ),
                label: _formatCount(commentsCount),
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng đăng nhập để bình luận!')),
                    );
                    context.go('/auth');
                    return;
                  }
                  _showCommentsBottomSheet(context, video.videoId, video.authorId);
                },
              );
            },
          ),
          const SizedBox(height: 18),

          // 4. Nút Chia sẻ (Nút tĩnh, chỉ cần truy cập ref khi bấm)
          _buildActionButton(
            icon: const Icon(
              Icons.share,
              color: Colors.white,
              size: 34,
            ),
            label: 'Chia sẻ',
            onTap: () {
              HapticFeedback.lightImpact();
              _showShareBottomSheet(context, ref, video);
            },
          ),
          const SizedBox(height: 18),

          // 5. Nút Bật/Tắt âm
          Consumer(
            builder: (context, ref, child) {
              final isMuted = ref.watch(videoMuteProvider);

              return _buildActionButton(
                icon: Icon(
                  isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 30,
                ),
                label: isMuted ? 'Muted' : 'Mở',
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(videoMuteProvider.notifier).state = !isMuted;
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: icon,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black54,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _showCommentsBottomSheet(BuildContext context, String videoId, String authorId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentBottomSheet(
          videoId: videoId,
          authorVideoId: authorId,
        );
      },
    );
  }

  void _showShareBottomSheet(BuildContext context, WidgetRef ref, VideoModel video) {
    final currentUser = ref.read(currentUserProvider);
    final isOwner = currentUser != null && currentUser.uid == video.authorId;
    final shareUrl = "https://hubertphung.github.io/toptop-share-page/?id=${video.videoId}";

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D1D1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Chia sẻ video',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Nút Tải xuống (kiểm tra allowDownload)
                    _buildShareOption(
                      icon: Icons.download_rounded,
                      label: 'Tải xuống',
                      color: video.allowDownload ? Colors.green : Colors.grey,
                      onTap: () {
                        if (!video.allowDownload) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Video này không cho phép tải xuống theo cài đặt của tác giả.'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đang tải xuống video...')),
                          );
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const SizedBox(width: 20),
                    _buildShareOption(
                      icon: Icons.copy,
                      label: 'Sao chép link',
                      color: Colors.blueGrey,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: shareUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép link liên kết!')),
                        );
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 20),
                    _buildShareOption(
                      icon: Icons.send,
                      label: 'Gửi tin nhắn',
                      color: Colors.blue,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sẽ hỗ trợ trong tương lai.')),
                        );
                        Navigator.pop(context);
                      },
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 20),
                      _buildShareOption(
                        icon: Icons.delete_forever_rounded,
                        label: 'Xóa video',
                        color: const Color(0xFFFE2C55),
                        onTap: () {
                          Navigator.pop(context); // Close bottom sheet
                          _showDeleteConfirmDialog(context, ref, video);
                        },
                      ),
                    ],
                    const SizedBox(width: 20),
                    _buildShareOption(
                      icon: Icons.more_horiz,
                      label: 'Thêm',
                      color: Colors.grey,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, VideoModel video) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Xóa video', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Bạn có chắc chắn muốn xóa video này? Hành động này không thể hoàn tác.',
            style: TextStyle(color: Colors.grey),
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
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                try {
                  await ref.read(videoRepositoryProvider).deleteVideo(
                        videoId: video.videoId,
                        authorId: video.authorId,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa video thành công!')),
                    );
                    context.go('/home'); // Redirect to home feed
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi xóa video: $e')),
                    );
                  }
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
