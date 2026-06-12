import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';

/// Màn hình Cài đặt & Quyền riêng tư
/// Port từ SettingsAndPrivacyActivity.java trong Android project
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '☀️ Sáng';
      case ThemeMode.dark:
        return '🌙 Tối';
      case ThemeMode.system:
        return '⚙️ Hệ thống';
    }
  }

  void _showThemeSelection(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final currentThemeMode = ref.read(themeNotifierProvider);
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Chọn giao diện',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: onSurfaceColor,
                  ),
                ),
              ),
              ListTile(
                leading: const Text('☀️', style: TextStyle(fontSize: 20)),
                title: Text(
                  'Sáng',
                  style: TextStyle(color: onSurfaceColor),
                ),
                trailing: currentThemeMode == ThemeMode.light
                    ? const Icon(Icons.check, color: Color(0xFFFE2C55))
                    : null,
                onTap: () {
                  themeNotifier.setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🌙', style: TextStyle(fontSize: 20)),
                title: Text(
                  'Tối',
                  style: TextStyle(color: onSurfaceColor),
                ),
                trailing: currentThemeMode == ThemeMode.dark
                    ? const Icon(Icons.check, color: Color(0xFFFE2C55))
                    : null,
                onTap: () {
                  themeNotifier.setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('⚙️', style: TextStyle(fontSize: 20)),
                title: Text(
                  'Hệ thống',
                  style: TextStyle(color: onSurfaceColor),
                ),
                trailing: currentThemeMode == ThemeMode.system
                    ? const Icon(Icons.check, color: Color(0xFFFE2C55))
                    : null,
                onTap: () {
                  themeNotifier.setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(authStateProvider).valueOrNull?.uid;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? AppTheme.textHint : Colors.grey[600];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cài đặt và quyền riêng tư',
          style: TextStyle(
            color: onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'TÀI KHOẢN',
              style: TextStyle(
                color: hintColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // Tùy chọn quản lý tài khoản
          ListTile(
            leading: Icon(Icons.person_outline_rounded, color: onSurface),
            title: Text(
              'Tài khoản',
              style: TextStyle(color: onSurface, fontSize: 15),
            ),
            trailing: Icon(Icons.chevron_right, color: hintColor),
            onTap: () {
              context.push('/settings/account');
            },
          ),

          // Tùy chọn chia sẻ hồ sơ
          ListTile(
            leading: Icon(Icons.share_outlined, color: onSurface),
            title: Text(
              'Chia sẻ hồ sơ',
              style: TextStyle(color: onSurface, fontSize: 15),
            ),
            trailing: Icon(Icons.chevron_right, color: hintColor),
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

          const Divider(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'HIỂN THỊ',
              style: TextStyle(
                color: hintColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // Tùy chọn chuyển đổi giao diện sáng/tối
          ListTile(
            leading: Icon(Icons.dark_mode_outlined, color: onSurface),
            title: Text(
              'Màn hình',
              style: TextStyle(color: onSurface, fontSize: 15),
            ),
            subtitle: Text(
              _getThemeLabel(ref.watch(themeNotifierProvider)),
              style: TextStyle(color: hintColor, fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right, color: hintColor),
            onTap: () => _showThemeSelection(context, ref),
          ),

          const Divider(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'ĐĂNG XUẤT',
              style: TextStyle(
                color: hintColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // Tùy chọn Đăng xuất
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
                  title: const Text('Đăng xuất'),
                  content: Text(
                    'Bạn có chắc chắn muốn đăng xuất khỏi TopTop?',
                    style: TextStyle(color: isDark ? AppTheme.textSecondary : Colors.black87),
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

