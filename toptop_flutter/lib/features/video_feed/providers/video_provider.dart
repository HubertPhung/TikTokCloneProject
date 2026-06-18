import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/models/profile_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/video_model.dart';
import '../models/ad_model.dart';
import '../models/feed_item.dart';
import '../repositories/video_repository.dart';

/// Provider cho VideoRepository
final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepository(
    firestore: ref.watch(firestoreProvider),
    database: ref.watch(realtimeDbProvider),
  );
});

/// StreamProvider cung cấp danh sách video đề xuất
final videoFeedStreamProvider = StreamProvider<List<VideoModel>>((ref) {
  return ref.watch(videoRepositoryProvider).watchRecommendedVideos();
});

/// Provider tải thông tin tác giả video
final videoAuthorProfileProvider =
    FutureProvider.family<ProfileModel?, String>((ref, authorId) async {
  return ref.watch(authRepositoryProvider).getProfile(authorId);
});

/// StateProvider lưu trữ trạng thái tắt âm toàn cục
final videoMuteProvider = StateProvider<bool>((ref) => false);

/// StreamProvider theo dõi lượng like và trạng thái like của người dùng đối với một video cụ thể
final videoLikesStateProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, videoId) {
  return ref.watch(videoRepositoryProvider).watchLikesState(videoId);
});

/// StreamProvider theo dõi số lượng bình luận thực tế của video (tối ưu hóa chỉ đọc trường totalComments)
final videoCommentsCountProvider =
    StreamProvider.family<int, String>((ref, videoId) {
  return ref.watch(firestoreProvider)
      .collection(AppConstants.videosCollection)
      .doc(videoId)
      .snapshots()
      .map((snapshot) => (snapshot.data()?['totalComments'] as num?)?.toInt() ?? 0);
});

/// StreamProvider theo dõi danh sách quảng cáo
final adsStreamProvider = StreamProvider<List<AdModel>>((ref) {
  return ref.watch(videoRepositoryProvider).watchAds();
});

/// Provider kết hợp video thường và quảng cáo tự động
final homeFeedProvider = Provider<AsyncValue<List<FeedItem>>>((ref) {
  final videosAsync = ref.watch(videoFeedStreamProvider);
  final adsAsync = ref.watch(adsStreamProvider);

  return videosAsync.when(
    data: (videos) {
      return adsAsync.when(
        data: (ads) {
          final feedItems = <FeedItem>[];
          int videoCounter = 0;
          int adIndex = 0;

          for (final video in videos) {
            feedItems.add(VideoItem(video));
            videoCounter++;

            if (videoCounter % 5 == 0 && ads.isNotEmpty) {
              final selectedAd = ads[adIndex % ads.length];
              feedItems.add(AdItem(selectedAd));
              adIndex++;
            }
          }
          return AsyncValue.data(feedItems);
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

