import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ad_model.dart';
import '../providers/video_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Widget phát Video Quảng cáo được tài trợ (Sponsored Ads)
/// Tự động phát/dừng dựa trên độ hiển thị và có thanh CTA kêu gọi hành động mở link ngoài.
class AdPlayerWidget extends ConsumerStatefulWidget {
  final AdModel ad;

  const AdPlayerWidget({
    super.key,
    required this.ad,
  });

  @override
  ConsumerState<AdPlayerWidget> createState() => _AdPlayerWidgetState();
}

class _AdPlayerWidgetState extends ConsumerState<AdPlayerWidget> {
  late VideoPlayerController _controller;
  Future<void>? _initializeFuture;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.ad.videoUri),
    );
    _initializeFuture = _controller.initialize().then((_) {
      if (mounted) {
        _controller.setLooping(true);
        final isMuted = ref.read(videoMuteProvider);
        _controller.setVolume(isMuted ? 0 : 1);
        
        if (_isVisible) {
          _controller.play();
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!_controller.value.isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  Future<void> _launchCtaUrl() async {
    final url = Uri.parse(widget.ad.targetUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở liên kết nhà tài trợ.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMuted = ref.watch(videoMuteProvider);
    if (_controller.value.isInitialized) {
      _controller.setVolume(isMuted ? 0 : 1);
    }

    return VisibilityDetector(
      key: Key('ad_vis_${widget.ad.adId}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        final visible = info.visibleFraction > 0.5;
        if (visible != _isVisible) {
          _isVisible = visible;
          if (_isVisible) {
            if (_controller.value.isInitialized) {
              _controller.play();
            }
          } else {
            if (_controller.value.isInitialized) {
              _controller.pause();
            }
          }
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Trình phát Video
          GestureDetector(
            onTap: _handleTap,
            child: FutureBuilder(
              future: _initializeFuture,
              builder: (context, snapshot) {
                if (_controller.value.isInitialized) {
                  return SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  );
                } else {
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          // Hiển thị icon Pause ở giữa màn hình nếu đang tạm dừng thủ công
          if (_controller.value.isInitialized && !_controller.value.isPlaying)
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),

          // Vòng xoay tải nếu video đang buffer
          if (_controller.value.isInitialized && _controller.value.isBuffering)
            const Align(
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),

          // Thanh tiến trình phát ở cuối video
          if (_controller.value.isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 60, // Chừa chỗ cho thanh CTA ở đáy
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppTheme.primaryColor,
                  bufferedColor: Colors.white10,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),

          // Cửa sổ thông tin tài trợ đè lên phía dưới bên trái
          Positioned(
            left: 16,
            bottom: 80,
            right: 90, // Để khoảng trống bên phải
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge Được tài trợ + Tên nhà tài trợ
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Được tài trợ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '@${widget.ad.sponsorName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Mô tả quảng cáo
                Text(
                  widget.ad.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Thanh Action Bar bên phải cho quảng cáo (chỉ hiển thị Nút Chia sẻ hoặc Báo cáo)
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nhà tài trợ Avatar giả lập
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: const Center(
                    child: Icon(Icons.business_rounded, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(height: 24),

                // Nút CTA nhỏ bên sườn
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 30),
                  onPressed: _launchCtaUrl,
                ),
                const Text(
                  'Mở',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Thanh CTA to, bắt mắt ở dưới đáy (Call To Action Bar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _launchCtaUrl,
              child: Container(
                height: 52,
                color: Colors.blueAccent.withValues(alpha: 0.95),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.ad.ctaText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
