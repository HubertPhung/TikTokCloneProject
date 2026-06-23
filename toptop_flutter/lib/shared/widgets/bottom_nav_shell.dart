import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Shell widget cho 5 tab chính, bám theo thanh điều hướng Android gốc.
class BottomNavShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    // Map UI index (0-4) → branch index (0-3, bỏ qua Add button ở giữa)
    final currentBranch = navigationShell.currentIndex;
    // Tính UI index từ branch index
    final uiIndex = currentBranch >= 2 ? currentBranch + 1 : currentBranch;

    return Scaffold(
      body: navigationShell,
      extendBody: false,
      bottomNavigationBar: Container(
        color: Colors.black,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Trang chủ',
                    isActive: uiIndex == 0,
                    onTap: () => _onTap(context, ref, 0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.search,
                    activeIcon: Icons.search,
                    label: 'Khám phá',
                    isActive: uiIndex == 1,
                    onTap: () => _onTap(context, ref, 1),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _AddVideoButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Vui lòng đăng nhập để đăng video!',
                              ),
                            ),
                          );
                          context.go('/auth');
                          return;
                        }
                        context.push('/camera');
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.inbox_outlined,
                    activeIcon: Icons.inbox,
                    label: 'Hộp thư',
                    isActive: uiIndex == 3,
                    onTap: () => _onTap(context, ref, 3),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Hồ sơ',
                    isActive: uiIndex == 4,
                    onTap: () => _onTap(context, ref, 4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, int uiIndex) {
    // Index 2 = nút Add Video → đã xử lý riêng
    if (uiIndex == 2) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null && (uiIndex == 3 || uiIndex == 4)) {
      final tabName = uiIndex == 3 ? 'hộp thư' : 'hồ sơ';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng đăng nhập để truy cập $tabName!')),
      );
      context.go('/auth');
      return;
    }

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
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: Colors.white, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faithful Flutter equivalent of Android's layered cyan/white/red add button.
class _AddVideoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddVideoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Đăng video',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 45,
          height: 30,
          child: Stack(
            children: [
              Positioned.fill(
                left: 0,
                right: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Positioned.fill(
                left: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Positioned.fill(
                left: 4,
                right: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
