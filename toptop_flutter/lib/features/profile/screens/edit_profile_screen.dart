import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Màn hình Chỉnh sửa hồ sơ cá nhân
/// Port từ EditProfileActivity.java
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  bool _isSavingAvatar = false;

  Future<void> _pickAndUploadAvatar(String uid) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Giới hạn kích thước ảnh
      );

      if (pickedFile != null) {
        setState(() {
          _isSavingAvatar = true;
        });

        // 1. Tải lên Firebase Storage và cập nhật Firestore
        await ref
            .read(profileRepositoryProvider)
            .updateAvatar(uid, pickedFile.path);

        // 2. Làm mới profile
        ref.invalidate(currentUserProfileProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật ảnh đại diện thành công!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải ảnh: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingAvatar = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final profileState = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Sửa hồ sơ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null || currentUser == null) {
            return const Center(
              child: Text('Không tìm thấy thông tin đăng nhập', style: TextStyle(color: Colors.white70)),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // 1. Phần chọn Ảnh đại diện
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.grey[900],
                        backgroundImage: profile.avatarUrl.isNotEmpty
                            ? CachedNetworkImageProvider(profile.avatarUrl)
                            : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                        child: profile.avatarUrl.isEmpty
                            ? const Icon(Icons.person, size: 54, color: Colors.white54)
                            : null,
                      ),
                      // Lớp đen mờ & icon camera
                      GestureDetector(
                        onTap: _isSavingAvatar ? null : () => _pickAndUploadAvatar(currentUser.uid),
                        child: Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black38,
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white70,
                            size: 28,
                          ),
                        ),
                      ),
                      if (_isSavingAvatar)
                        const SizedBox(
                          width: 108,
                          height: 108,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isSavingAvatar ? null : () => _pickAndUploadAvatar(currentUser.uid),
                  child: const Text(
                    'Thay đổi ảnh',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Danh sách các trường thông tin
                const Divider(color: Colors.white12, height: 1),

                // Thay đổi Username
                _buildEditRow(
                  label: 'Username',
                  value: '@${profile.username}',
                  onTap: () {
                    context.push('/profile/edit/username');
                  },
                ),

                // Thay đổi Bio (Ở đây đã có inline editor trên ProfileScreen,
                // nhưng vẫn có thể dẫn link hoặc xem giá trị tại đây)
                _buildEditRow(
                  label: 'Tiểu sử',
                  value: profile.bio.isNotEmpty ? profile.bio : 'Chưa thiết lập',
                  onTap: () {
                    // Trở về trang profile để nhấn vào tiểu sử sửa
                    context.pop();
                  },
                ),

                // Thay đổi Ngày sinh (Birthdate)
                _buildEditRow(
                  label: 'Ngày sinh',
                  value: profile.birthdate.isNotEmpty ? profile.birthdate : 'Chưa cập nhật',
                  onTap: () {
                    context.push('/profile/edit/birthdate');
                  },
                ),

                // Đổi mật khẩu
                _buildEditRow(
                  label: 'Mật khẩu',
                  value: '••••••••',
                  onTap: () {
                    context.push('/settings/password');
                  },
                ),
                const Divider(color: Colors.white12, height: 1),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        error: (error, _) => Center(
          child: Text('Lỗi: ${error.toString()}', style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _buildEditRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 7,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.white54, fontSize: 14),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
