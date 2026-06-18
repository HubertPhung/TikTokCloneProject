import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Màn hình Cài đặt Giao diện (Appearance Screen)
/// Cho phép người dùng tùy chọn Sáng, Tối, hoặc Hệ thống với giao diện cao cấp
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Giao diện',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'Chọn giao diện hiển thị cho ứng dụng TopTop',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Mockup Phone Previews (Side by side) ─────────────────────────
          Row(
            children: [
              // Light Mode Preview Card
              Expanded(
                child: GestureDetector(
                  onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
                  child: Column(
                    children: [
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: themeMode == ThemeMode.light
                                ? const Color(0xFFFE2C55)
                                : Colors.black.withValues(alpha: 0.08),
                            width: themeMode == ThemeMode.light ? 2.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Header bar representation
                            Positioned(
                              top: 12,
                              left: 12,
                              right: 12,
                              child: Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F1F3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            // Content line 1
                            Positioned(
                              top: 40,
                              left: 12,
                              width: 80,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5E5EA),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            // Content line 2 (App bubble)
                            Positioned(
                              top: 60,
                              left: 12,
                              right: 36,
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFE2C55).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 44,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFE2C55),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sáng',
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: themeMode == ThemeMode.light
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Dark Mode Preview Card
              Expanded(
                child: GestureDetector(
                  onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
                  child: Column(
                    children: [
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161618),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: themeMode == ThemeMode.dark
                                ? const Color(0xFFFE2C55)
                                : Colors.white.withValues(alpha: 0.08),
                            width: themeMode == ThemeMode.dark ? 2.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Header bar representation
                            Positioned(
                              top: 12,
                              left: 12,
                              right: 12,
                              child: Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2E),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            // Content line 1
                            Positioned(
                              top: 40,
                              left: 12,
                              width: 80,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3A3A3C),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            // Content line 2 (App bubble)
                            Positioned(
                              top: 60,
                              left: 12,
                              right: 36,
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFE2C55).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 44,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFE2C55),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tối',
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: themeMode == ThemeMode.dark
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Text Options list ─────────────────────────────────────────────
          _buildThemeCard(context, [
            _buildThemeOptionTile(
              context: context,
              title: '☀️ Sáng',
              isSelected: themeMode == ThemeMode.light,
              onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
            ),
            _buildDivider(isDark),
            _buildThemeOptionTile(
              context: context,
              title: '🌙 Tối',
              isSelected: themeMode == ThemeMode.dark,
              onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
            ),
            _buildDivider(isDark),
            _buildThemeOptionTile(
              context: context,
              title: '⚙️ Theo hệ thống',
              subtitle: 'Tự động đồng bộ màu sắc với thiết bị của bạn',
              isSelected: themeMode == ThemeMode.system,
              onTap: () => themeNotifier.setThemeMode(ThemeMode.system),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, List<Widget> children) {
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

  Widget _buildThemeOptionTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final hintColor = Theme.of(context).brightness == Brightness.dark ? AppTheme.textHint : Colors.grey[600];

    return Material(
      color: Colors.transparent,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: TextStyle(
            color: onSurface,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(color: hintColor, fontSize: 11))
            : null,
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFE2C55), size: 20)
            : Icon(Icons.circle_outlined, color: hintColor, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDark ? const Color(0xFF333333) : const Color(0xFFE8E8E8),
    );
  }
}
