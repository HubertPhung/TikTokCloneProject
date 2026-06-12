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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Section: Tài khoản
          _buildSectionHeader('TÀI KHOẢN', hintColor),
          const SizedBox(height: 8),
          _buildCard(context, [
            _buildSettingTile(
              icon: Icons.person_outline_rounded,
              title: 'Tài khoản',
              iconColor: onSurface,
              titleColor: onSurface,
              hintColor: hintColor,
              onTap: () => context.push('/settings/account'),
            ),
            Divider(height: 1, color: isDark ? const Color(0xFF333333) : const Color(0xFFE8E8E8)),
            _buildSettingTile(
              icon: Icons.share_outlined,
              title: 'Chia sẻ hồ sơ',
              iconColor: onSurface,
              titleColor: onSurface,
              hintColor: hintColor,
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
          ]),

          const SizedBox(height: 20),

          // Section: Hiển thị
          _buildSectionHeader('HIỂN THỊ', hintColor),
          const SizedBox(height: 8),
          _buildCard(context, [
            _buildSettingTile(
              icon: Icons.dark_mode_outlined,
              title: 'Màn hình',
              subtitle: _getThemeLabel(ref.watch(themeNotifierProvider)),
              iconColor: onSurface,
              titleColor: onSurface,
              hintColor: hintColor,
              onTap: () => _showThemeSelection(context, ref),
            ),
          ]),

          const SizedBox(height: 20),

          // Section: Đăng xuất
          _buildSectionHeader('ĐĂNG XUẤT', hintColor),
          const SizedBox(height: 8),
          _buildCard(context, [
            _buildSettingTile(
              icon: Icons.logout_rounded,
              title: 'Đăng xuất',
              iconColor: const Color(0xFFFE2C55),
              titleColor: const Color(0xFFFE2C55),
              hintColor: hintColor,
              isBold: true,
              showChevron: false,
              onTap: () {
                _showLogoutDialog(context, ref, isDark);
              },
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE8E8E8),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    required Color titleColor,
    Color? hintColor,
    bool isBold = false,
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontSize: 15,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: hintColor, fontSize: 12))
          : null,
      trailing: showChevron ? Icon(Icons.chevron_right, color: hintColor, size: 20) : null,
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, bool isDark) {
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
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ref.read(authRepositoryProvider).signOut().then((_) {
                  if (context.mounted) {
                    context.go('/auth');
                  }
                });
              },
              child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
