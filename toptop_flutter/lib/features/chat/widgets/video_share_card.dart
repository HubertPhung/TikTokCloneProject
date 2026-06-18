import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

/// Widget hiển thị Video Share Card kiểu TikTok trong tin nhắn chat.
/// Fetch thông tin video + tác giả từ Firestore và hiển thị dạng preview card.
class VideoShareCard extends StatelessWidget {
  final String videoId;

  const VideoShareCard({super.key, required this.videoId});

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A1F) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final textColor = isDark ? Colors.white : const Color(0xFF161722);
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection(AppConstants.videosCollection)
          .doc(videoId)
          .get(),
      builder: (context, snapshot) {
        // ── Loading ──────────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton(cardBg, borderColor);
        }

        // ── Error / Not Found ─────────────────────────────────────────────
        final data = snapshot.data?.data();
        if (data == null) {
          return _buildErrorCard(isDark, subColor);
        }

        final thumbnailUrl = data['thumbnailUri'] as String? ?? '';
        final description = data['description'] as String? ?? 'Video TopTop';
        final authorId = data['authorId'] as String? ?? '';
        final watchCount = (data['watchCount'] as num?)?.toInt() ?? 0;

        return GestureDetector(
          onTap: () => context.push('/video/$videoId'),
          child: Container(
            width: 220,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Thumbnail ────────────────────────────────────────────
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: AspectRatio(
                    aspectRatio: 9 / 14,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail image
                        thumbnailUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: thumbnailUrl,
                                fit: BoxFit.cover,
                                placeholder: (context2, url) => Container(
                                  color: isDark
                                      ? const Color(0xFF242428)
                                      : const Color(0xFFE8E8E8),
                                ),
                                errorWidget: (context2, url, err) => Container(
                                  color: isDark
                                      ? const Color(0xFF242428)
                                      : const Color(0xFFE8E8E8),
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.white38),
                                ),
                              )
                            : Container(
                                color: isDark
                                    ? const Color(0xFF242428)
                                    : const Color(0xFFE8E8E8),
                              ),

                        // Gradient overlay từ dưới lên
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 60,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Play button giữa
                        Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 1.5),
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 30),
                          ),
                        ),

                        // TopTop watermark
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.logoGradient,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'TopTop',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // View count ở góc dưới trái
                        Positioned(
                          left: 8,
                          bottom: 6,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_arrow,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                _formatCount(watchCount),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Info section ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Author info
                      _AuthorRow(
                          authorId: authorId, isDark: isDark, subColor: subColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(Color bg, Color border) {
    return Container(
      width: 220,
      height: 280,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(bool isDark, Color subColor) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1F) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.broken_image_outlined,
              color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Video không còn tồn tại',
              style: TextStyle(color: subColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Row hiển thị avatar + username của tác giả video
class _AuthorRow extends StatelessWidget {
  final String authorId;
  final bool isDark;
  final Color subColor;

  const _AuthorRow({
    required this.authorId,
    required this.isDark,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    if (authorId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection(AppConstants.profilesCollection)
          .doc(authorId)
          .get(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final username = data?['username'] as String? ?? '';
        final avatarUrl = data?['avatarUrl'] as String? ?? '';

        return Row(
          children: [
            // Avatar
            SizedBox(
              width: 18,
              height: 18,
              child: CircleAvatar(
                radius: 9,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFE8E8E8),
                backgroundImage: avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl, maxWidth: 40)
                    : null,
                child: avatarUrl.isEmpty
                    ? Icon(Icons.person,
                        size: 12, color: subColor)
                    : null,
              ),
            ),
            const SizedBox(width: 5),

            // Username
            Expanded(
              child: Text(
                username.isNotEmpty ? '@$username' : 'TopTop User',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
