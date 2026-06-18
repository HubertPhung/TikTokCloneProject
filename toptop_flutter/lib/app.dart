import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/firebase_providers.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/chat/providers/chat_provider.dart';

/// Widget gốc của ứng dụng TopTop
/// Cấu hình Material 3 theme, GoRouter, và quản lý Presence người dùng
class TopTopApp extends ConsumerStatefulWidget {
  const TopTopApp({super.key});

  @override
  ConsumerState<TopTopApp> createState() => _TopTopAppState();
}

class _TopTopAppState extends ConsumerState<TopTopApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final currentUid = ref.read(authStateProvider).valueOrNull?.uid;
    if (currentUid == null) return;

    final chatRepo = ref.read(chatRepositoryProvider);
    if (state == AppLifecycleState.resumed) {
      chatRepo.updatePresence(currentUid, true);
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive ||
               state == AppLifecycleState.detached) {
      chatRepo.updatePresence(currentUid, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    // Kích hoạt tự động Presence & Kết nối (Riverpod tự động hủy subscription cũ khi logout)
    ref.watch(currentUserPresenceProvider);

    return MaterialApp.router(
      title: 'TopTop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

