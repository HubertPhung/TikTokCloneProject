// ignore_for_file: prefer_initializing_formals

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../core/constants/app_constants.dart';
import '../models/video_model.dart';
import '../models/ad_model.dart';

/// Repository xử lý logic liên quan đến Video (feed, like, view count, sở thích)
/// Port từ VideoFragment.java, VideoAdapter.java, RecommendationHelper.java
class VideoRepository {
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _database;

  VideoRepository({
    required FirebaseFirestore firestore,
    required FirebaseDatabase database,
  })  : _firestore = firestore,
        _database = database;

  /// Stream danh sách video được đề xuất (ưu tiên chiến dịch Đà Lạt lên trước)
  /// Port từ VideoFragment.loadVideos() và RecommendationHelper
  Stream<List<VideoModel>> watchRecommendedVideos() {
    return _firestore
        .collection(AppConstants.videosCollection)
        .orderBy('timestamp', descending: true)
        .limit(AppConstants.videoFeedLimit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => VideoModel.fromMap(doc.data()))
          .where((video) =>
              video.moderationStatus != 'rejected' &&
              video.moderationStatus != 'pending')
          .toList();

      // Sắp xếp ưu tiên các video thuộc chiến dịch Đà Lạt (theo hashtags hoặc location)
      list.sort((a, b) {
        final aIsCampaign = a.location == 'Da Lat' ||
            a.hashtags.any((tag) => const ['dalat', 'dalatdulich', 'khamphadalat']
                .contains(tag.toLowerCase().replaceAll('#', '')));
        final bIsCampaign = b.location == 'Da Lat' ||
            b.hashtags.any((tag) => const ['dalat', 'dalatdulich', 'khamphadalat']
                .contains(tag.toLowerCase().replaceAll('#', '')));

        if (aIsCampaign && !bIsCampaign) return -1;
        if (!aIsCampaign && bIsCampaign) return 1;
        return b.timestamp.compareTo(a.timestamp);
      });

      return list;
    });
  }

  /// Bật/Tắt thích video (Like/Unlike)
  /// Port từ VideoAdapter.VideoViewHolder.toggleLikeLocal()
  Future<void> toggleLike({
    required String videoId,
    required String authorId,
    required String currentUid,
    required bool isLiked,
    required String currentUsername,
  }) async {
    final likeRef = _firestore.collection('likes').doc(videoId);
    final videoRef =
        _firestore.collection(AppConstants.videosCollection).doc(videoId);
    final profileRef =
        _firestore.collection(AppConstants.profilesCollection).doc(authorId);

    if (isLiked) {
      // 1. Cập nhật Firestore likes/{videoId}
      await likeRef.set({
        currentUid: true,
      }, SetOptions(merge: true));

      // 2. Tăng số like của video và profile tác giả
      await videoRef.update({
        'totalLikes': FieldValue.increment(1),
      });
      await profileRef.update({
        'likes': FieldValue.increment(1),
      });

      // 3. Gửi thông báo Like qua RTDB
      final notifRef = _database
          .ref(AppConstants.notificationsPath)
          .child(authorId)
          .push();
      await notifRef.set({
        'fromUsername': currentUsername.isNotEmpty ? currentUsername : 'Ai đó',
        'action': AppConstants.actionLike,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      // 1. Xóa user khỏi Firestore likes/{videoId}
      await likeRef.update({
        currentUid: FieldValue.delete(),
      });

      // 2. Giảm số like của video và profile tác giả
      await videoRef.update({
        'totalLikes': FieldValue.increment(-1),
      });
      await profileRef.update({
        'likes': FieldValue.increment(-1),
      });
    }
  }

  /// Tăng lượt xem cho video (Watch Count)
  /// Port từ VideoAdapter.updateWatchCount()
  Future<void> incrementWatchCount({
    required String videoId,
    required String authorId,
  }) async {
    // 1. Tăng trong videos/{videoId}
    await _firestore
        .collection(AppConstants.videosCollection)
        .doc(videoId)
        .update({'watchCount': FieldValue.increment(1)});

    // 2. Tăng trong video_summaries/{videoId}
    await _firestore
        .collection('video_summaries')
        .doc(videoId)
        .update({'watchCount': FieldValue.increment(1)});

    // 3. Tăng trong profiles/{authorId}/public_videos/{videoId}
    await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(authorId)
        .collection('public_videos')
        .doc(videoId)
        .update({'watchCount': FieldValue.increment(1)});
  }

  /// Ghi nhận sở thích xem video thông qua phân tách hashtag
  /// Port từ RecommendationHelper.recordInterest()
  Future<void> recordInterest({
    required String description,
    required String currentUid,
  }) async {
    if (description.isEmpty || currentUid.isEmpty) return;

    final regex = RegExp(r'#([A-Za-z0-9_\u00C0-\u1EF9-]+)');
    final matches = regex.allMatches(description);
    final hashtags = matches.map((m) => m.group(1)!.toLowerCase()).toList();

    if (hashtags.isEmpty) return;

    final batch = _firestore.batch();
    for (final tag in hashtags) {
      final tagRef = _firestore
          .collection(AppConstants.userInterestsCollection)
          .doc(currentUid)
          .collection('tags')
          .doc(tag);

      batch.set(
        tagRef,
        {
          'count': FieldValue.increment(1),
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  /// Lấy danh sách tags người dùng quan tâm nhất (giới hạn 3)
  /// Port từ RecommendationHelper.getTopInterests()
  Future<List<String>> getTopInterests(String currentUid) async {
    if (currentUid.isEmpty) return [];

    final snapshot = await _firestore
        .collection(AppConstants.userInterestsCollection)
        .doc(currentUid)
        .collection('tags')
        .orderBy('count', descending: true)
        .limit(3)
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// Stream số lượng like và trạng thái like của người dùng hiện tại
  Stream<Map<String, dynamic>> watchLikesState(String videoId) {
    return _firestore.collection('likes').doc(videoId).snapshots().map((doc) {
      if (!doc.exists) return {'count': 0, 'users': <String, bool>{}};
      final data = doc.data() ?? {};
      int count = 0;
      data.forEach((key, value) {
        if (value == true) count++;
      });
      return {
        'count': count,
        'users': Map<String, bool>.from(data),
      };
    });
  }

  /// Xóa video khỏi Firestore và các collection liên quan (likes, comments, summaries, public_videos)
  /// Port từ DeleteVideoSettingActivity.java
  Future<void> deleteVideo({
    required String videoId,
    required String authorId,
  }) async {
    final batch = _firestore.batch();

    // 1. Tìm và xóa các hashtag liên quan đến videoId này
    final hashtagsQuery = await _firestore
        .collection('hashtags')
        .where('videoId', isEqualTo: videoId)
        .get();
    for (final doc in hashtagsQuery.docs) {
      batch.delete(doc.reference);
    }

    // 2. Xóa các tài liệu chính của video
    batch.delete(_firestore.collection(AppConstants.videosCollection).doc(videoId));
    batch.delete(_firestore.collection('video_summaries').doc(videoId));
    batch.delete(_firestore
        .collection(AppConstants.profilesCollection)
        .doc(authorId)
        .collection('public_videos')
        .doc(videoId));

    // 3. Xóa likes và comments liên kết
    batch.delete(_firestore.collection('likes').doc(videoId));
    batch.delete(_firestore.collection('comments').doc(videoId));

    // Thực hiện batch write
    await batch.commit();
  }

  /// Theo dõi danh sách video quảng cáo từ Firestore
  /// Có hỗ trợ dữ liệu giả định (Mock Data) nếu collection trống
  Stream<List<AdModel>> watchAds() {
    return _firestore.collection('ads').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return [
          AdModel(
            adId: 'mock_ad_1',
            videoUri: 'https://assets.mixkit.co/videos/preview/mixkit-forest-stream-in-the-sunlight-529-large.mp4',
            sponsorName: 'Đà Lạt Travel Co.',
            description: 'Khám phá Đà Lạt mộng mơ với tour du lịch 3 ngày 2 đêm trọn gói chỉ từ 1.990.000 VNĐ. Đặt ngay hôm nay nhận ưu đãi 20%!',
            ctaText: 'Đặt tour ngay',
            targetUrl: 'https://dalattrip.com',
          ),
          AdModel(
            adId: 'mock_ad_2',
            videoUri: 'https://assets.mixkit.co/videos/preview/mixkit-waterfall-in-forest-2213-large.mp4',
            sponsorName: 'Thác Datanla Adventure',
            description: 'Trải nghiệm đu dây vượt thác, xe trượt núi dài nhất Đông Nam Á tại Datanla Đà Lạt. Mở cửa từ 7:00 đến 17:00 hằng ngày.',
            ctaText: 'Xem chi tiết',
            targetUrl: 'https://datanla.vn',
          ),
        ];
      }
      return snapshot.docs.map((doc) => AdModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  /// Ghi nhận lượt xem cho chiến dịch quảng bá Đà Lạt
  Future<void> recordCampaignView(String videoId) async {
    final docRef = _firestore.collection('campaign_analytics').doc(videoId);
    await docRef.set({
      'videoId': videoId,
      'campaign': 'dalat',
      'views': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  /// Ghi nhận lượt click vào badge/hashtag chiến dịch Đà Lạt
  Future<void> recordCampaignClick(String videoId) async {
    final docRef = _firestore.collection('campaign_analytics').doc(videoId);
    await docRef.set({
      'videoId': videoId,
      'campaign': 'dalat',
      'clicks': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
}
