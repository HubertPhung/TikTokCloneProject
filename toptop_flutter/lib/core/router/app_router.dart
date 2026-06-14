import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:toptop_flutter/features/auth/providers/auth_provider.dart';
import 'package:toptop_flutter/features/auth/screens/auth_choice_screen.dart';
import 'package:toptop_flutter/features/auth/screens/login_screen.dart';
import 'package:toptop_flutter/features/auth/screens/signup_screen.dart';
import 'package:toptop_flutter/features/auth/screens/splash_screen.dart';
import 'package:toptop_flutter/features/chat/screens/inbox_screen.dart';
import 'package:toptop_flutter/features/chat/screens/chat_screen.dart';
import 'package:toptop_flutter/features/chat/screens/notifications_screen.dart';
import 'package:toptop_flutter/features/profile/screens/profile_screen.dart';
import 'package:toptop_flutter/features/profile/screens/edit_profile_screen.dart';
import 'package:toptop_flutter/features/profile/screens/edit_field_screen.dart';
import 'package:toptop_flutter/features/profile/screens/follow_list_screen.dart';
import 'package:toptop_flutter/features/settings/screens/settings_screen.dart';
import 'package:toptop_flutter/features/settings/screens/account_settings_screen.dart';
import 'package:toptop_flutter/features/settings/screens/change_password_screen.dart';
import 'package:toptop_flutter/features/settings/screens/delete_account_screen.dart';
import 'package:toptop_flutter/features/search/screens/search_screen.dart';
import 'package:toptop_flutter/features/video_feed/screens/video_feed_screen.dart';
import 'package:toptop_flutter/features/video_feed/screens/single_video_screen.dart';
import 'package:toptop_flutter/features/video_upload/screens/camera_screen.dart';
import 'package:toptop_flutter/features/video_upload/screens/video_description_screen.dart';
import 'package:toptop_flutter/shared/widgets/bottom_nav_shell.dart';

/// Cấu hình GoRouter cho toàn bộ ứng dụng
/// Bao gồm redirect logic kiểm tra auth state
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  CustomTransitionPage<void> buildSlidePage({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
    );
  }

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    // Redirect logic: kiểm tra đăng nhập
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoading = authState.isLoading;
      final currentPath = state.uri.path;

      // Đang tải auth state → không redirect
      if (isLoading) return null;

      // Splash screen → xử lý riêng
      if (currentPath == '/') return null;

      // Nếu chưa đăng nhập và đang ở trang cần auth
      final isAuthRoute = currentPath.startsWith('/auth');
      if (!isLoggedIn && !isAuthRoute) {
        return '/auth';
      }

      // Nếu đã đăng nhập và đang ở trang auth → về home
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },

    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthChoiceScreen(),
        routes: [
          GoRoute(
            path: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'signup',
            builder: (context, state) => const SignupScreen(),
          ),
        ],
      ),

      // Main App Shell (Bottom Navigation)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Home (Video Feed)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const VideoFeedScreen(),
              ),
            ],
          ),

          // Tab 1: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),

          // Tab 2: Inbox
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                builder: (context, state) => const InboxScreen(),
              ),
            ],
          ),

          // Tab 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Camera (bên ngoài shell — fullscreen)
      GoRoute(
        path: '/camera',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const CameraScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
        ),
      ),

      // Thêm mô tả & Đăng video (bên ngoài shell — fullscreen)
      GoRoute(
        path: '/video/description',
        builder: (context, state) {
          final videoPath = state.uri.queryParameters['videoPath'];
          final videoId = state.uri.queryParameters['videoId'];
          return VideoDescriptionScreen(
            videoPath: videoPath,
            videoId: videoId,
          );
        },
      ),

      // Chi tiết Video (bên ngoài shell — fullscreen)
      GoRoute(
        path: '/video/:videoId',
        builder: (context, state) {
          final videoId = state.pathParameters['videoId'] ?? '';
          return SingleVideoScreen(videoId: videoId);
        },
      ),

      // Profile người khác (bên ngoài shell — fullscreen)
      GoRoute(
        path: '/user/:userId',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return buildSlidePage(
            key: state.pageKey,
            child: ProfileScreen(userId: userId),
          );
        },
      ),

      // Followers list
      GoRoute(
        path: '/user/:userId/followers',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return buildSlidePage(
            key: state.pageKey,
            child: FollowListScreen(userId: userId, initialTabIndex: 1),
          );
        },
      ),

      // Following list
      GoRoute(
        path: '/user/:userId/following',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return buildSlidePage(
            key: state.pageKey,
            child: FollowListScreen(userId: userId, initialTabIndex: 0),
          );
        },
      ),

      // Edit profile
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) => buildSlidePage(
          key: state.pageKey,
          child: const EditProfileScreen(),
        ),
      ),

      // Edit field
      GoRoute(
        path: '/profile/edit/:field',
        pageBuilder: (context, state) {
          final field = state.pathParameters['field'] ?? '';
          return buildSlidePage(
            key: state.pageKey,
            child: EditFieldScreen(field: field),
          );
        },
      ),

      // Màn hình chat chi tiết
      GoRoute(
        path: '/chat/:receiverId',
        pageBuilder: (context, state) {
          final receiverId = state.pathParameters['receiverId'] ?? '';
          final name = state.uri.queryParameters['name'] ?? '';
          final avatar = state.uri.queryParameters['avatar'] ?? '';
          return buildSlidePage(
            key: state.pageKey,
            child: ChatScreen(
              receiverId: receiverId,
              receiverName: name,
              receiverAvatar: avatar,
            ),
          );
        },
      ),

      // Màn hình tất cả thông báo hoạt động
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => buildSlidePage(
          key: state.pageKey,
          child: const NotificationsScreen(),
        ),
      ),

      // Các màn hình Cài đặt & Quyền riêng tư
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => buildSlidePage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'account',
            pageBuilder: (context, state) => buildSlidePage(
              key: state.pageKey,
              child: const AccountSettingsScreen(),
            ),
          ),
          GoRoute(
            path: 'password',
            pageBuilder: (context, state) => buildSlidePage(
              key: state.pageKey,
              child: const ChangePasswordScreen(),
            ),
          ),
          GoRoute(
            path: 'delete-account',
            pageBuilder: (context, state) => buildSlidePage(
              key: state.pageKey,
              child: const DeleteAccountScreen(),
            ),
          ),
        ],
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy trang: ${state.uri.path}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    ),
  );
});
