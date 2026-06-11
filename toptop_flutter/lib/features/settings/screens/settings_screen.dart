import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

/// Màn hình Cài đặt & Quyền riêng tư
/// Port từ SettingsAndPrivacyActivity.java trong Android project
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(authStateProvider).valueOrNull?.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cài đặt và quyền riêng tư',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'TÀI KHOẢN',
              style: TextStyle(
                color: AppTheme.textHint,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // Tùy chọn quản lý tài khoản
          ListTile(
            leading: const Icon(Icons.person_outline_rounded, color: Colors.white),
            title: const Text(
              'Tài khoản',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
            onTap: () {
              context.push('/settings/account');
            },
          ),

          // Tùy chọn chia sẻ hồ sơ
          ListTile(
            leading: const Icon(Icons.share_outlined, color: Colors.white),
            title: const Text(
              'Chia sẻ hồ sơ',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
            onTap: () {
              if (currentUid != null) {
                final link = 'http://toptoptoptop.com/$currentUid';
                Clipboard.setData(ClipboardData(text: link)).then((_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép liên kết hồ sơ của bạn!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                });
              }
            },
          ),

          const Divider(color: AppTheme.dividerColor, height: 32),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'ĐĂNG XUẤT',
              style: TextStyle(
                color: AppTheme.textHint,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // Tùy chọn Đăng xuất (Bổ sung thiết thực so với bản Android)
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFFE2C55)),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Color(0xFFFE2C55), fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'Bạn có chắc chắn muốn đăng xuất khỏi TopTop?',
                    style: TextStyle(color: AppTheme.textSecondary),
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
                        Navigator.pop(context); // Close dialog
                        // Đăng xuất và điều hướng về màn hình chọn Auth
                        ref.read(authRepositoryProvider).signOut().then((_) {
                          if (context.mounted) {
                            context.go('/auth');
                          }
                        });
                      },
                      child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
