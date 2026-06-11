import 'package:flutter/material.dart';
import '../models/video_model.dart';

/// Widget hiển thị thông tin đè lên Video (Tên tác giả, mô tả, hashtag)
/// Port từ VideoAdapter.VideoViewHolder.updateMetadataUI()
class VideoOverlay extends StatelessWidget {
  final VideoModel video;

  const VideoOverlay({
    super.key,
    required this.video,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      bottom: 20,
      right: 90, // Chừa khoảng trống cho thanh VideoActionBar bên phải
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tên tác giả
          Text(
            video.username.isNotEmpty ? '@${video.username}' : '@User',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black54,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Mô tả video
          Text(
            video.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black54,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Hashtags
          if (video.hashtags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: video.hashtags.map((tag) {
                return GestureDetector(
                  onTap: () {
                    // Sẽ tích hợp với tính năng tìm kiếm ở Sprint 4
                    debugPrint('Clicked hashtag: #$tag');
                  },
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black54,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
