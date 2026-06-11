import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/chat_provider.dart';

/// Widget hiển thị danh sách người dùng đang hoạt động (Online) theo chiều ngang
/// Port từ ActiveUserAdapter.java và InboxFragment.java
class ActiveUsersRow extends ConsumerWidget {
  const ActiveUsersRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUsersAsync = ref.watch(activeUsersProvider);

    return activeUsersAsync.when(
      data: (userIds) {
        if (userIds.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              final userId = userIds[index];
              return _ActiveUserItem(userId: userId);
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _ActiveUserItem extends ConsumerWidget {
  final String userId;

  const _ActiveUserItem({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider(userId));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final displayName = profile.username.isNotEmpty ? profile.username : 'User';

        return GestureDetector(
          onTap: () {
            // Click vào text/item ngoài avatar -> đi tới Profile
            context.push('/user/${profile.userId}');
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            width: 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    // Click vào Avatar -> Mở màn hình Chat
                    context.push(
                      '/chat/${profile.userId}?name=${Uri.encodeComponent(profile.username)}&avatar=${Uri.encodeComponent(profile.avatarUrl)}',
                    );
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: profile.avatarUrl.isNotEmpty
                            ? NetworkImage(profile.avatarUrl)
                            : null,
                        child: profile.avatarUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 28)
                            : null,
                      ),
                      Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.backgroundColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(width: 70),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
