import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/models/profile_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/video_model.dart';
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

/// StreamProvider theo dõi số lượng bình luận thực tế của video
final videoCommentsCountProvider =
    StreamProvider.family<int, String>((ref, videoId) {
  return ref.watch(firestoreProvider)
      .collection('comments')
      .where('videoId', isEqualTo: videoId)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});
