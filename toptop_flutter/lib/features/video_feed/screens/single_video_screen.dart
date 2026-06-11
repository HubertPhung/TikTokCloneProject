import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../models/video_model.dart';
import '../widgets/video_action_bar.dart';
import '../widgets/video_overlay.dart';
import '../widgets/video_player_widget.dart';

/// Màn hình hiển thị một Video cụ thể (dành cho Deep Link hoặc khi click từ Profile)
/// Port từ VideoActivity.java
class SingleVideoScreen extends ConsumerWidget {
  final String videoId;

  const SingleVideoScreen({
    super.key,
    required this.videoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.videosCollection)
            .doc(videoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            );
          }

          final doc = snapshot.data;
          if (doc == null || !doc.exists || doc.data() == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Video này đã bị gỡ bỏ hoặc không tồn tại.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Quay lại', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          final video = VideoModel.fromMap(doc.data()!);

          if (video.moderationStatus == 'rejected') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Video này đã bị khóa do vi phạm tiêu chuẩn cộng đồng.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Quay lại', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Trình phát Video
              VideoPlayerWidget(video: video),

              // 2. Overlay thông tin tác giả và mô tả
              VideoOverlay(video: video),

              // 3. Sidebar tương tác
              VideoActionBar(video: video),

              // 4. Nút Back (Quay lại) nổi lên trên
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 12,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
