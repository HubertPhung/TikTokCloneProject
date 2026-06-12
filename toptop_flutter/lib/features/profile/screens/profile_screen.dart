import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
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
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.white),
                title: const Text('Cài đặt & Quyền riêng tư', style: TextStyle(color: Colors.white)),
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

    if (profileId.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Vui lòng đăng nhập để xem hồ sơ', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final profileState = ref.watch(userProfileStreamProvider(profileId));
    final videosState = ref.watch(userVideosStreamProvider(profileId));

    // Watch follow status
    final followCompositeKey = "${currentUser?.uid}_$profileId";
    final isFollowing = ref.watch(followStatusStreamProvider(followCompositeKey)).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: !isMe
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              )
            : null,
        title: profileState.when(
          data: (profile) => Text(
            profile?.fullname ?? 'Hồ sơ',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          loading: () => const SizedBox(),
          error: (error, _) => const SizedBox(),
        ),
        actions: [
          if (isMe)
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _showSettingsBottomSheet(context),
            ),
        ],
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('Hồ sơ không tồn tại hoặc đã bị xóa.', style: TextStyle(color: Colors.white70)),
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
                  const SizedBox(height: 16),

                  // 1. Ảnh đại diện (Click để xem ảnh to)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AvatarPreviewDialog(avatarUrl: profile.avatarUrl),
                      );
                    },
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey[900],
                      backgroundImage: profile.avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(profile.avatarUrl)
                          : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                      child: profile.avatarUrl.isEmpty
                          ? const Icon(Icons.person, size: 48, color: Colors.white54)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Username hiển thị
                  Text(
                    '@${profile.username}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Hàng chỉ số (Đang theo dõi, Người theo dõi, Lượt thích)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMetricItem(
                        label: 'Đang theo dõi',
                        value: profile.following.toString(),
                        onTap: () => context.push(
                          '/user/$profileId/following',
                        ),
                      ),
                      _buildDivider(),
                      _buildMetricItem(
                        label: 'Người theo dõi',
                        value: profile.followers.toString(),
                        onTap: () => context.push(
                          '/user/$profileId/followers',
                        ),
                      ),
                      _buildDivider(),
                      _buildMetricItem(
                        label: 'Thích',
                        value: profile.likes.toString(),
                        onTap: null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Các nút Hành động (Sửa hồ sơ / Follow + Message)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: isMe
                        ? Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => context.push('/profile/edit'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white30),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    minimumSize: const Size(0, 45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: const Text(
                                    'Sửa hồ sơ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 45,
                                child: OutlinedButton(
                                  onPressed: () {
                                    final link = 'https://toptop.app/user/$profileId';
                                    Clipboard.setData(ClipboardData(text: link));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã sao chép liên kết hồ sơ!'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  child: const Icon(Icons.share_outlined, size: 20),
                                ),
                              ),
                            ],
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
                                      borderRadius: BorderRadius.circular(4),
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
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white30),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: const Text(
                                    'Nhắn tin',
                                    style: TextStyle(fontWeight: FontWeight.bold),
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
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Thêm tiểu sử của bạn...',
                                  hintStyle: TextStyle(color: Colors.white30),
                                  focusedBorder: UnderlineInputBorder(
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
                                      color: profile.bio.isNotEmpty ? Colors.white70 : Colors.white30,
                                      fontSize: 14,
                                      fontStyle: profile.bio.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit, color: Colors.white30, size: 14),
                                ],
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // 6. Lưới video tóm tắt
                  const Divider(color: Colors.white12, height: 1),
                  videosState.when(
                    data: (videos) {
                      if (videos.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              Icon(Icons.video_library_outlined, color: Colors.grey[700], size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                'Chưa có video nào',
                                style: TextStyle(color: Colors.white30, fontSize: 14),
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

                          return GestureDetector(
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
                          );
                        },
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.all(48),
                      child: Text('Lỗi: ${error.toString()}', style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ),
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
    return Container(
      width: 1,
      height: 12,
      color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
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
