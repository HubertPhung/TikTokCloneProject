import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/video_model.dart';
import '../providers/video_provider.dart';

/// Trạng thái hoạt ảnh trái tim khi double tap
class FloatingHeart {
  final UniqueKey key;
  final Offset position;
  final double rotation;

  FloatingHeart({
    required this.key,
    required this.position,
    required this.rotation,
  });
}

/// Widget phát Video chính, xử lý vòng đời của VideoPlayerController,
/// cử chỉ tap/double-tap, và phát tự động qua VisibilityDetector.
class VideoPlayerWidget extends ConsumerStatefulWidget {
  final VideoModel video;

  const VideoPlayerWidget({
    super.key,
    required this.video,
  });

  @override
  ConsumerState<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends ConsumerState<VideoPlayerWidget>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isVisible = false;
  bool _hasLoggedWatch = false;
  final List<FloatingHeart> _hearts = [];

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUri),
    );
    _controller.initialize().then((_) {
      if (mounted) {
        _controller.setLooping(true);
        // Đồng bộ âm lượng ban đầu với mute state
        final isMuted = ref.read(videoMuteProvider);
        _controller.setVolume(isMuted ? 0 : 1);
        
        if (_isVisible) {
          _controller.play();
          _trackWatch();
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

  /// Ghi nhận lượt xem và sở thích (chỉ một lần duy nhất khi video bắt đầu được xem)
  void _trackWatch() {
    if (_hasLoggedWatch) return;
    _hasLoggedWatch = true;

    final repo = ref.read(videoRepositoryProvider);
    final user = ref.read(currentUserProvider);

    // 1. Tăng watch count
    repo.incrementWatchCount(
      videoId: widget.video.videoId,
      authorId: widget.video.authorId,
    );

    // 2. Ghi lại sở thích nếu đã đăng nhập
    if (user != null) {
      repo.recordInterest(
        description: widget.video.description,
        currentUid: user.uid,
      );
    }

    // 3. Tăng lượt xem cho chiến dịch quảng bá Đà Lạt nếu hợp lệ
    final isDalatCampaign = widget.video.location == 'Da Lat' ||
        widget.video.hashtags.any((tag) => const ['dalat', 'dalatdulich', 'khamphadat']
            .contains(tag.toLowerCase().replaceAll('#', '')));
    if (isDalatCampaign) {
      repo.recordCampaignView(widget.video.videoId);
    }
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

  void _handleDoubleTap(Offset localPosition) {
    // Rung xúc giác khi double tap thả tim
    HapticFeedback.mediumImpact();

    // 1. Thêm trái tim bay
    final randomAngle = (math.Random().nextDouble() * 40 - 20) * math.pi / 180;
    final newHeart = FloatingHeart(
      key: UniqueKey(),
      position: localPosition,
      rotation: randomAngle,
    );

    setState(() {
      _hearts.add(newHeart);
    });

    // Xóa trái tim sau khi kết thúc hoạt ảnh (700ms)
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _hearts.removeWhere((heart) => heart.key == newHeart.key);
        });
      }
    });

    // 2. Tự động thích nếu chưa thích
    _likeVideoIfNotAlready();
  }

  Future<void> _likeVideoIfNotAlready() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final likesState = ref.read(videoLikesStateProvider(widget.video.videoId)).valueOrNull;
    final likedUsers = likesState?['users'] as Map<String, dynamic>? ?? {};
    final isAlreadyLiked = likedUsers[currentUser.uid] == true;

    if (!isAlreadyLiked) {
      final userProfile = ref.read(currentUserProfileProvider).valueOrNull;
      final username = userProfile?.username ?? currentUser.email?.split('@')[0] ?? '';
      await ref.read(videoRepositoryProvider).toggleLike(
            videoId: widget.video.videoId,
            authorId: widget.video.authorId,
            currentUid: currentUser.uid,
            isLiked: true,
            currentUsername: username,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe trạng thái tắt âm toàn cục
    final isMuted = ref.watch(videoMuteProvider);
    if (_controller.value.isInitialized) {
      _controller.setVolume(isMuted ? 0 : 1);
    }

    return VisibilityDetector(
      key: Key('video_vis_${widget.video.videoId}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        final visible = info.visibleFraction > 0.5;
        if (visible != _isVisible) {
          _isVisible = visible;
          if (_isVisible) {
            if (_controller.value.isInitialized) {
              _controller.play();
              _trackWatch();
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
            onDoubleTapDown: (details) => _handleDoubleTap(details.localPosition),
            child: _controller.value.isInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                      ),
                    ),
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

          // Hiển thị vòng xoay tải nếu video đang buffer
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
              bottom: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white70,
                  bufferedColor: Colors.white10,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),

          // Hoạt ảnh trái tim khi Double Tap
          ..._hearts.map((heart) {
            return Positioned(
              left: heart.position.dx - 50,
              top: heart.position.dy - 50,
              child: RepaintBoundary(
                child: TweenAnimationBuilder<double>(
                  key: heart.key,
                  duration: const Duration(milliseconds: 700),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    // value chạy từ 0.0 -> 1.0
                    // 0.0 -> 0.3: Scale up và Fade in
                    // 0.3 -> 1.0: Fly up, Rotate và Fade out
                    double scale = 1.0;
                    double opacity = 1.0;
                    double translateUp = 0.0;

                    if (value < 0.3) {
                      scale = (value / 0.3) * 1.3;
                      opacity = value / 0.3;
                    } else {
                      scale = 1.3 - ((value - 0.3) / 0.7) * 0.5;
                      opacity = 1.0 - (value - 0.3) / 0.7;
                      translateUp = ((value - 0.3) / 0.7) * -120;
                    }

                    return Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, translateUp),
                        child: Transform.rotate(
                          angle: heart.rotation * (value * 1.5),
                          child: Transform.scale(
                            scale: scale.clamp(0.0, 2.0),
                            child: const Icon(
                              Icons.favorite,
                              size: 100,
                              color: Color(0xFFFE2C55),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
