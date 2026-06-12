import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: feedState.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không có video nào được đăng.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              if (item is AdItem) {
                return AdPlayerWidget(ad: item.ad);
              } else if (item is VideoItem) {
                final video = item.video;

                return Stack(
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
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
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
    );
  }
}

