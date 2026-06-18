import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/avatar_preview_dialog.dart';

/// Màn hình hồ sơ người dùng (Hồ sơ của mình hoặc người khác)
/// Port từ ProfileFragment.java và FollowActivity.java
class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({
    super.key,
    this.userId,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _bioController = TextEditingController();
  bool _isEditingBio = false;
  String _originalBio = '';

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  void _showSettingsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.settings, color: onSurface),
                title: Text('Cài đặt & Quyền riêng tư', style: TextStyle(color: onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.primaryColor),
                title: const Text('Đăng xuất', style: TextStyle(color: AppTheme.primaryColor)),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/auth');
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    // Nếu không truyền userId, mặc định là hiển thị profile của user hiện tại
    final profileId = widget.userId ?? currentUser?.uid ?? '';
    final isMe = profileId == currentUser?.uid;

    // Theme-aware colors
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final bgColor = theme.scaffoldBackgroundColor;
    final onSurface = cs.onSurface;
    final divColor = isDark ? const Color(0xFF333333) : const Color(0xFFE3E3E4);
    final hintTextColor = isDark ? Colors.white30 : Colors.black38;
    final btnBgColor = isDark ? const Color(0xFF242428) : const Color(0xFFF1F1F3);

    if (profileId.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text('Vui lòng đăng nhập để xem hồ sơ', style: TextStyle(color: onSurface.withValues(alpha: 0.5))),
        ),
      );
    }

    final profileState = ref.watch(userProfileStreamProvider(profileId));
    final videosState = ref.watch(userVideosStreamProvider(profileId));

    // Watch follow status
    final followCompositeKey = "${currentUser?.uid}_$profileId";
    final isFollowing = ref.watch(followStatusStreamProvider(followCompositeKey)).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: !isMe
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: onSurface),
                onPressed: () => context.pop(),
              )
            : null,
        title: profileState.when(
          data: (profile) => Text(
            profile?.fullname ?? 'Hồ sơ',
            style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          loading: () => const SizedBox(),
          error: (error, _) => const SizedBox(),
        ),
        actions: [
          if (isMe)
            IconButton(
              icon: Icon(Icons.menu, color: onSurface),
              onPressed: () => _showSettingsBottomSheet(context),
            ),
        ],
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text('Hồ sơ không tồn tại hoặc đã bị xóa.', style: TextStyle(color: onSurface.withValues(alpha: 0.7))),
            );
          }

          // Khởi tạo text controller cho bio
          if (!_isEditingBio && _bioController.text != profile.bio) {
            _bioController.text = profile.bio;
            _originalBio = profile.bio;
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Kích hoạt đồng bộ hóa lại lượng follow từ repo
              await ref.read(profileRepositoryProvider).syncFollowCounts(profileId);
            },
            color: AppTheme.primaryColor,
            backgroundColor: const Color(0xFF1D1D1F),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // 1. Ảnh đại diện với gradient ring
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AvatarPreviewDialog(avatarUrl: profile.avatarUrl),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.logoGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: bgColor,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                          backgroundImage: profile.avatarUrl.isNotEmpty
                              ? CachedNetworkImageProvider(profile.avatarUrl, maxWidth: 120)
                              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                          child: profile.avatarUrl.isEmpty
                              ? Icon(Icons.person, size: 48, color: onSurface.withValues(alpha: 0.5))
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Username hiển thị
                  Text(
                    '@${profile.username}',
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Glassmorphism stats card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            label: 'Đang theo dõi',
                            value: profile.following.toString(),
                            onTap: () => context.push(
                              '/user/$profileId/following',
                            ),
                          ),
                        ),
                        _buildDivider(),
                        Expanded(
                          child: _buildMetricItem(
                            label: 'Người theo dõi',
                            value: profile.followers.toString(),
                            onTap: () => context.push(
                              '/user/$profileId/followers',
                            ),
                          ),
                        ),
                        _buildDivider(),
                        Expanded(
                          child: _buildMetricItem(
                            label: 'Thích',
                            value: profile.likes.toString(),
                            onTap: null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Các nút Hành động (Sửa hồ sơ / Follow + Message)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: isMe
                        ? SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => context.push('/profile/edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: onSurface,
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                minimumSize: const Size(0, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: btnBgColor,
                              ),
                              child: Text(
                                'Sửa hồ sơ',
                                style: TextStyle(fontWeight: FontWeight.w600, color: onSurface, fontSize: 14),
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              // Nút Follow / Unfollow
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (currentUser == null) {
                                      context.go('/auth');
                                      return;
                                    }
                                    final repo = ref.read(profileRepositoryProvider);
                                    if (isFollowing) {
                                      await repo.unfollowUser(
                                        currentUid: currentUser.uid,
                                        targetUid: profileId,
                                      );
                                    } else {
                                      final myProfile = ref.read(currentUserProfileProvider).valueOrNull;
                                      final myUsername = myProfile?.username ?? currentUser.email?.split('@')[0] ?? '';
                                      await repo.followUser(
                                        currentUid: currentUser.uid,
                                        targetUid: profileId,
                                        currentUsername: myUsername,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFollowing ? Colors.grey[850] : AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    isFollowing ? 'Hủy theo dõi' : 'Theo dõi',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Nút Nhắn tin
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    if (currentUser == null) {
                                      context.go('/auth');
                                      return;
                                    }
                                    context.push('/chat/$profileId');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: onSurface,
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    backgroundColor: btnBgColor,
                                  ),
                                  child: Text(
                                    'Nhắn tin',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: onSurface, fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Phần Tiểu sử (Bio)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _isEditingBio
                        ? Column(
                            children: [
                              TextField(
                                controller: _bioController,
                                style: TextStyle(color: onSurface),
                                decoration: InputDecoration(
                                  hintText: 'Thêm tiểu sử của bạn...',
                                  hintStyle: TextStyle(color: hintTextColor),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: divColor),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: AppTheme.primaryColor),
                                  ),
                                ),
                                maxLength: 80,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _bioController.text = _originalBio;
                                        _isEditingBio = false;
                                      });
                                    },
                                    child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await ref.read(profileRepositoryProvider).updateBio(
                                            profileId,
                                            _bioController.text.trim(),
                                          );
                                      setState(() {
                                        _originalBio = _bioController.text.trim();
                                        _isEditingBio = false;
                                      });
                                    },
                                    child: const Text('Cập nhật', style: TextStyle(color: AppTheme.primaryColor)),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: isMe
                                ? () {
                                    setState(() {
                                      _isEditingBio = true;
                                    });
                                  }
                                : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    profile.bio.isNotEmpty ? profile.bio : (isMe ? 'Chưa có tiểu sử. Ấn để thêm.' : 'Chưa có tiểu sử.'),
                                    style: TextStyle(
                                      color: profile.bio.isNotEmpty
                                          ? onSurface.withValues(alpha: 0.7)
                                          : onSurface.withValues(alpha: 0.35),
                                      fontSize: 14,
                                      fontStyle: profile.bio.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit, color: onSurface.withValues(alpha: 0.3), size: 14),
                                ],
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // 6. Lưới video tóm tắt
                  Divider(color: divColor, height: 1),
                  videosState.when(
                    data: (videos) {
                      if (videos.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              Icon(Icons.video_library_outlined, color: Colors.grey[700], size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Chưa có video nào',
                                style: TextStyle(
                                  color: isDark ? Colors.white30 : Colors.black38,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 3 / 4,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index];

                          return RepaintBoundary(
                            child: GestureDetector(
                              onTap: () {
                                context.push('/video/${video.videoId}');
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Thumbnail (Dùng CachedNetworkImage)
                                  CachedNetworkImage(
                                    imageUrl: video.thumbnailUri,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 250, // Tối ưu kích thước lưu cache bộ nhớ
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[900],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[900],
                                      child: const Icon(Icons.broken_image, color: Colors.white24),
                                    ),
                                  ),

                                  // Xem lượt xem ở góc trái dưới
                                  Positioned(
                                    left: 6,
                                    bottom: 6,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.play_arrow_outlined,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          _formatWatchCount(video.watchCount),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const ShimmerVideoGrid(),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.all(48),
                      child: Text('Lỗi: ${error.toString()}', style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                  const SizedBox(height: 80), // Chừa khoảng trống tránh bị đè bởi BottomNavigationBar
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        error: (error, _) => Center(
          child: Text('Lỗi tải hồ sơ: ${error.toString()}', style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 16,
      color: isDark ? Colors.white12 : Colors.black12,
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatWatchCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
