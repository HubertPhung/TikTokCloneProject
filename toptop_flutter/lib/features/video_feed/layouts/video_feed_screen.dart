import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/shimmer_loading.dart';
import '../providers/video_provider.dart';
import '../widgets/video_action_bar.dart';
import '../widgets/video_overlay.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/ad_player_widget.dart';
import '../models/feed_item.dart';

/// Màn hình chính phát video cuộn dọc (Video Feed)
/// Port từ VideoFragment.java và hỗ trợ thêm quảng cáo và chiến dịch du lịch
class VideoFeedScreen extends ConsumerWidget {
  const VideoFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(homeFeedProvider);
    final selectedTab = ref.watch(homeTabProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Màn hình Feed chính
          feedState.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.video_library_outlined,
                        color: Colors.white54,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        selectedTab == HomeTab.lamDong
                            ? 'Chưa có video nào về Lâm Đồng.'
                            : 'Không có video nào được đăng.',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // Làm mới provider tương ứng với tab đang chọn
                  if (selectedTab == HomeTab.lamDong) {
                    ref.invalidate(lamDongVideoFeedProvider);
                    await ref.read(lamDongVideoFeedProvider.future);
                  } else if (selectedTab == HomeTab.following) {
                    ref.invalidate(followingVideoFeedProvider);
                    await ref.read(followingVideoFeedProvider.future);
                  } else {
                    ref.invalidate(videoFeedProvider);
                    await ref.read(videoFeedProvider.future);
                  }
                },
                color: Colors.white,
                backgroundColor: Colors.black,
                child: PageView.builder(
                  key: ValueKey(selectedTab), // Đảm bảo reset PageView khi đổi tab
                  scrollDirection: Axis.vertical,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    if (item is AdItem) {
                      return AdPlayerWidget(ad: item.ad);
                    } else if (item is VideoItem) {
                      final video = item.video;

                      return GestureDetector(
                        onHorizontalDragEnd: (details) {
                          // Nhận diện vuốt trái (từ phải qua trái) trên video feed để chuyển sang trang cá nhân tác giả
                          if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
                            context.push('/user/${video.authorId}');
                          }
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 1. Trình phát Video nền
                            VideoPlayerWidget(video: video),

                            // 2. Overlay thông tin ở góc trái dưới
                            VideoOverlay(
                              video: video,
                              onCampaignBadgeTap: () {
                                // Ghi nhận click chiến dịch
                                ref.read(videoRepositoryProvider).recordCampaignClick(video.videoId);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cảm ơn bạn đã tham gia chiến dịch quảng bá du lịch Đà Lạt! 🌲'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),

                            // 3. Action bar dọc ở góc phải dưới
                            VideoActionBar(video: video),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
            loading: () => const ShimmerVideoFeed(),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tải danh sách video: ${error.toString()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // 2. Thanh ngang đề xuất trên cùng
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTopTab(ref, 'Đang Follow', HomeTab.following, selectedTab == HomeTab.following),
                    _buildDivider(),
                    _buildTopTab(ref, 'Lâm Đồng', HomeTab.lamDong, selectedTab == HomeTab.lamDong),
                    _buildDivider(),
                    _buildTopTab(ref, 'Dành cho bạn', HomeTab.forYou, selectedTab == HomeTab.forYou),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        '|',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTopTab(WidgetRef ref, String title, HomeTab tab, bool isActive) {
    return GestureDetector(
      onTap: () {
        ref.read(homeTabProvider.notifier).state = tab;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              shadows: const [
                Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 1)),
              ],
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 28,
              color: Colors.white,
            ),
        ],
      ),
    );
  }
}

