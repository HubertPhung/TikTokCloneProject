import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Shell widget chứa BottomNavigationBar premium cho 5 tab chính
/// Port từ HomeScreenActivity.java — nâng cấp TikTok premium style
class BottomNavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    // Map UI index (0-4) → branch index (0-3, bỏ qua Add button ở giữa)
    final currentBranch = navigationShell.currentIndex;
    // Tính UI index từ branch index
    final uiIndex = currentBranch >= 2 ? currentBranch + 1 : currentBranch;

    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withValues(alpha: 0.85),
              border: const Border(
                top: BorderSide(
                  color: Color(0xFF2A2A2A),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: 'Trang chủ',
                      isActive: uiIndex == 0,
                      onTap: () => _onTap(0),
                    ),
                    _NavItem(
                      icon: Icons.search,
                      activeIcon: Icons.search,
                      label: 'Khám phá',
                      isActive: uiIndex == 1,
                      onTap: () => _onTap(1),
                    ),
                    // Nút Add Video ở giữa — Premium TikTok style
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/camera');
                      },
                      child: Container(
                        width: 48,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: AppTheme.logoGradient,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    _NavItem(
                      icon: Icons.inbox_outlined,
                      activeIcon: Icons.inbox,
                      label: 'Hộp thư',
                      isActive: uiIndex == 3,
                      onTap: () => _onTap(3),
                    ),
                    _NavItem(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'Hồ sơ',
                      isActive: uiIndex == 4,
                      onTap: () => _onTap(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int uiIndex) {
    // Index 2 = nút Add Video → đã xử lý riêng
    if (uiIndex == 2) return;
    final branchIndex = uiIndex > 2 ? uiIndex - 1 : uiIndex;
    
    // Rung xúc giác khi chuyển tab
    HapticFeedback.selectionClick();
    
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }
}

/// Tab item với active dot indicator
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.white : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            // Active dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isActive ? 4 : 0,
              height: isActive ? 4 : 0,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
