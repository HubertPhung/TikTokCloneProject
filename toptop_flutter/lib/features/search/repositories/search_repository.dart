// ignore_for_file: prefer_initializing_formals

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/models/profile_model.dart';
import '../../video_feed/models/video_model.dart';

/// Repository thực hiện các truy vấn tìm kiếm người dùng và video trên Firestore
class SearchRepository {
  final FirebaseFirestore _firestore;

  SearchRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  /// Tìm kiếm người dùng theo username (prefix matching)
  Future<List<ProfileModel>> searchUsers(String key) async {
    if (key.trim().isEmpty) return [];
    
    final snapshot = await _firestore
        .collection(AppConstants.profilesCollection)
        .orderBy('username')
        .startAt([key])
        .endAt(['$key\uf8ff'])
        .limit(5)
        .get();

    return snapshot.docs
        .map((doc) => ProfileModel.fromMap(doc.data()))
        .toList();
  }

  /// Tìm kiếm video theo hashtag hoặc description
  Future<List<VideoModel>> searchVideos(String key) async {
    if (key.trim().isEmpty) return [];

    final cleanKey = key.trim();
    
    // Nếu từ khóa bắt đầu bằng #, tìm kiếm theo mảng hashtags
    if (cleanKey.startsWith('#') && !cleanKey.contains(' ')) {
      final tag = cleanKey.substring(1).toLowerCase();
      final snapshot = await _firestore
          .collection(AppConstants.videosCollection)
          .where('hashtags', arrayContains: tag)
          .limit(10)
          .get();

      return _filterApprovedVideos(snapshot);
    }

    // Ngược lại, tìm kiếm theo mô tả (prefix matching trên description)
    final snapshot = await _firestore
        .collection(AppConstants.videosCollection)
        .orderBy('description')
        .startAt([cleanKey])
        .endAt(['$cleanKey\uf8ff'])
        .limit(10)
        .get();

    final results = _filterApprovedVideos(snapshot);

    // Nếu không tìm thấy kết quả theo mô tả, thử tìm kiếm theo hashtag tương đương (fallback)
    if (results.isEmpty) {
      final fallbackSnapshot = await _firestore
          .collection(AppConstants.videosCollection)
          .where('hashtags', arrayContains: cleanKey.toLowerCase())
          .limit(10)
          .get();
      return _filterApprovedVideos(fallbackSnapshot);
    }

    return results;
  }

  /// Tải các video thịnh hành nhất (xếp theo watchCount giảm dần)
  Future<List<VideoModel>> loadTrendingVideos() async {
    final snapshot = await _firestore
        .collection(AppConstants.videosCollection)
        .orderBy('watchCount', descending: true)
        .limit(20)
        .get();

    return _filterApprovedVideos(snapshot);
  }

  /// Thu thập các hashtag thịnh hành từ 30 video được xem nhiều nhất
  Future<List<String>> loadTrendingTags() async {
    final snapshot = await _firestore
        .collection(AppConstants.videosCollection)
        .orderBy('watchCount', descending: true)
        .limit(30)
        .get();

    final Set<String> uniqueTags = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final hashtags = data['hashtags'] as List<dynamic>?;
      if (hashtags != null) {
        for (final tag in hashtags) {
          if (uniqueTags.length < 10) {
            uniqueTags.add('#${tag.toString().toLowerCase()}');
          }
        }
      }
    }

    // Fallback nếu không có hashtag nào
    if (uniqueTags.isEmpty) {
      return ['#trending', '#fyp', '#tiktok'];
    }

    return uniqueTags.toList();
  }

  /// Lọc các video đã được duyệt (không bao gồm rejected hoặc pending)
  List<VideoModel> _filterApprovedVideos(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final List<VideoModel> list = [];
    for (final doc in snapshot.docs) {
      final model = VideoModel.fromMap(doc.data(), doc.id);
      if (model.moderationStatus == 'rejected' || model.moderationStatus == 'pending') {
        continue;
      }
      list.add(model);
    }
    return list;
  }
}
