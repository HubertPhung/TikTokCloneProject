import 'package:flutter/material.dart';
import '../models/video_model.dart';

/// Widget hiển thị thông tin đè lên Video (Tên tác giả, mô tả, hashtag)
/// Port từ VideoAdapter.VideoViewHolder.updateMetadataUI()
class VideoOverlay extends StatelessWidget {
  final VideoModel video;
  final VoidCallback? onCampaignBadgeTap;

  const VideoOverlay({
    super.key,
    required this.video,
    this.onCampaignBadgeTap,
  });

  bool get _isDalatCampaign {
    return video.location == 'Da Lat' ||
        video.hashtags.any((tag) => const ['dalat', 'dalatdulich', 'khamphadalat']
            .contains(tag.toLowerCase().replaceAll('#', '')));
  }

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
          // Thẻ Chiến dịch Đà Lạt
          if (_isDalatCampaign) ...[
            GestureDetector(
              onTap: onCampaignBadgeTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFE2C55).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🌲', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      'Du Lịch Đà Lạt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

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
