import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Shell widget chứa BottomNavigationBar cho 5 tab chính
/// Port từ HomeScreenActivity.java (bottom buttons: Home, Search, Add, Inbox, Profile)
class BottomNavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color(0xFF2A2A2A),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            // Index 2 = nút Add Video → điều hướng đến camera (bên ngoài shell)
            if (index == 2) {
              context.push('/camera');
              return;
            }
            navigationShell.goBranch(
              // Map UI index sang branch index (bỏ qua index 2 - nút Add)
              index > 2 ? index - 1 : index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              activeIcon: Icon(Icons.search, color: Colors.white),
              label: 'Khám phá',
            ),
            // Nút Add Video ở giữa (thiết kế đặc biệt)
            BottomNavigationBarItem(
              icon: Container(
                width: 44,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.secondaryColor,
                      AppTheme.primaryColor,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.inbox_outlined),
              activeIcon: Icon(Icons.inbox),
              label: 'Hộp thư',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}
