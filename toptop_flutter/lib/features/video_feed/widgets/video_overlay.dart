import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/video_model.dart';

/// Widget hiển thị thông tin đè lên Video (Tên tác giả, mô tả, hashtag, nhạc)
/// Port từ VideoAdapter.VideoViewHolder.updateMetadataUI() — Premium upgrade
class VideoOverlay extends StatefulWidget {
  final VideoModel video;
  final VoidCallback? onCampaignBadgeTap;

  const VideoOverlay({
    super.key,
    required this.video,
    this.onCampaignBadgeTap,
  });

  @override
  State<VideoOverlay> createState() => _VideoOverlayState();
}

class _VideoOverlayState extends State<VideoOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _marqueeController;

  @override
  void initState() {
    super.initState();
    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    super.dispose();
  }

  bool get _isDalatCampaign {
    return widget.video.location == 'Da Lat' ||
        widget.video.hashtags.any((tag) => const ['dalat', 'dalatdulich', 'khamphadalat']
            .contains(tag.toLowerCase().replaceAll('#', '')));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      bottom: 0,
      right: 0,
      child: Container(
        // Gradient overlay phía dưới
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black87,
              Colors.black54,
              Colors.transparent,
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        padding: const EdgeInsets.only(left: 16, right: 90, bottom: 20, top: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thẻ Chiến dịch Đà Lạt
            if (_isDalatCampaign) ...[
              GestureDetector(
                onTap: widget.onCampaignBadgeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFE2C55), Color(0xFF8B2C4E)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
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
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Tên tác giả
            Text(
              widget.video.username.isNotEmpty ? '@${widget.video.username}' : '@User',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(blurRadius: 6, color: Colors.black87, offset: Offset(0, 1)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Mô tả video
            if (widget.video.description.isNotEmpty)
              Text(
                widget.video.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black54, offset: Offset(0, 1)),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            // Hashtag pills
            if (widget.video.hashtags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: widget.video.hashtags.take(5).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Music marquee row
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.music_note, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 16,
                    child: AnimatedBuilder(
                      animation: _marqueeController,
                      builder: (context, child) {
                        return ClipRect(
                          child: FractionalTranslation(
                            translation: Offset(1.0 - 2.0 * _marqueeController.value, 0),
                            child: Text(
                              '♪ Nhạc gốc — ${widget.video.username.isNotEmpty ? widget.video.username : "TopTop"} • Đang phát',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
