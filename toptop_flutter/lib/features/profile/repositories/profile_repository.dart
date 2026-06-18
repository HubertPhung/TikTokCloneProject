// ignore_for_file: prefer_initializing_formals

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/models/profile_model.dart';
import '../../video_feed/models/video_summary_model.dart';

/// Repository xử lý thông tin hồ sơ, chỉnh sửa avatar/bio/username, theo dõi (follow/unfollow)
/// Port từ ProfileFragment.java, FollowActivity.java, EditProfileActivity.java, EditActivity.java
class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _database;
  final FirebaseStorage _storage;

  ProfileRepository({
    required FirebaseFirestore firestore,
    required FirebaseDatabase database,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _database = database,
        _storage = storage;

  /// Lấy thông tin profile bằng UID
  Future<ProfileModel?> getProfile(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(uid)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return ProfileModel.fromMap(doc.data()!);
  }

  /// Theo dõi (Stream) thông tin profile bằng UID
  Stream<ProfileModel?> watchProfile(String uid) {
    return _firestore
        .collection(AppConstants.profilesCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ProfileModel.fromMap(doc.data()!);
    });
  }

  /// Cập nhật Bio
  /// Port từ ProfileFragment.updateBio()
  Future<void> updateBio(String uid, String bio) async {
    await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(uid)
        .update({'bio': bio});
  }

  /// Cập nhật ảnh đại diện lên Firebase Storage
  /// Port từ EditProfileActivity.uploadAvatarToCloudinary() nhưng dùng Firebase Storage nội bộ
  Future<String> updateAvatar(String uid, String localPath) async {
    final file = File(localPath);
    final storageRef = _storage.ref().child('avatars').child('$uid.jpg');

    // 1. Tải lên Storage
    final uploadTask = await storageRef.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // 2. Cập nhật profiles collection
    await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(uid)
        .update({
      'avatar': downloadUrl,
      'avatarUrl': downloadUrl, // Giữ cả hai field để tương thích ngược
    });

    // 3. Cập nhật users collection
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'avatar': downloadUrl,
      'avatarUrl': downloadUrl,
    });

    return downloadUrl;
  }

  /// Cập nhật Username (kiểm tra tính khả dụng trước)
  /// Port từ EditActivity.checkUsernameAvailability() và updateUsername()
  Future<bool> updateUsername({
    required String uid,
    required String newUsername,
  }) async {
    // 1. Kiểm tra xem username đã bị ai sử dụng chưa
    final checkQuery = await _firestore
        .collection(AppConstants.usersCollection)
        .where('username', isEqualTo: newUsername)
        .get();

    for (final doc in checkQuery.docs) {
      if (doc.id != uid) {
        return false; // Đã bị trùng
      }
    }

    // 2. Tiến hành cập nhật ở cả users và profiles
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'username': newUsername});

    await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(uid)
        .update({'username': newUsername});

    // 3. Đồng bộ hóa tên người dùng vào tất cả video đã đăng
    final videosQuery = await _firestore
        .collection(AppConstants.videosCollection)
        .where('authorId', isEqualTo: uid)
        .get();

    if (videosQuery.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in videosQuery.docs) {
        batch.update(doc.reference, {'username': newUsername});
      }
      await batch.commit();
    }

    return true;
  }

  /// Cập nhật Ngày sinh
  /// Port từ EditActivity.updateBirthdate()
  Future<void> updateBirthdate({
    required String uid,
    required String birthdate,
  }) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'birthdate': birthdate});

    await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(uid)
        .update({'birthdate': birthdate});
  }

  /// Stream danh sách video tóm tắt (lưới video của user)
  /// Port từ ProfileFragment.setVideoSummaries()
  Stream<List<VideoSummaryModel>> watchUserVideos(String uid) {
    return _firestore
        .collection(AppConstants.videosCollection)
        .where('authorId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      // Sắp xếp in-memory theo timestamp giảm dần
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aTime = (a.data()['timestamp'] as num?)?.toInt() ?? 0;
        final bTime = (b.data()['timestamp'] as num?)?.toInt() ?? 0;
        return bTime.compareTo(aTime);
      });

      final list = <VideoSummaryModel>[];
      final limitedDocs = docs.take(50);

      for (final doc in limitedDocs) {
        final data = doc.data();
        final modStatus = data['moderationStatus'] as String?;
        if (modStatus == 'rejected') continue;

        String thumb = data['thumbnailUri'] as String? ?? '';
        if (thumb.isEmpty) {
          thumb = data['thumbnailUrl'] as String? ?? '';
        }
        if (thumb.isEmpty) {
          final videoUri = data['videoUri'] as String? ?? '';
          if (videoUri.contains('cloudinary.com')) {
            thumb = videoUri.replaceAll('.mp4', '.jpg');
            if (thumb.contains('/upload/')) {
              thumb = thumb.replaceAll('/upload/', '/upload/so_0/');
            }
          } else {
            thumb = 'https://picsum.photos/200/300'; // Dự phòng
          }
        }

        final vId = data['videoId'] as String? ?? '';
        list.add(VideoSummaryModel(
          videoId: vId.isNotEmpty ? vId : doc.id,
          thumbnailUri: thumb,
          watchCount: (data['watchCount'] as num?)?.toInt() ?? 0,
        ));
      }
      return list;
    });
  }

  /// Kiểm tra trạng thái follow
  /// Port từ ProfileFragment.handleFollow() và FollowActivity
  Stream<bool> watchFollowStatus({
    required String currentUid,
    required String targetUid,
  }) {
    return _firestore
        .collection(AppConstants.profilesCollection)
        .doc(currentUid)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Theo dõi người dùng (Follow)
  /// Port từ ProfileFragment.handleUnfollowed() và FollowActivity.handleUnfollowed()
  Future<void> followUser({
    required String currentUid,
    required String targetUid,
    required String currentUsername,
  }) async {
    // 1. Thêm vào following của current user
    await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(currentUid)
        .collection('following')
        .doc(targetUid)
        .set({'userID': targetUid});

    // 2. Thêm vào followers của target user
    await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(targetUid)
        .collection('followers')
        .doc(currentUid)
        .set({'userID': currentUid});

    // 3. Đồng bộ lại follow counts
    await syncFollowCounts(currentUid);
    await syncFollowCounts(targetUid);

    // 4. Gửi thông báo Follow qua RTDB
    final notifRef = _database
        .ref(AppConstants.notificationsPath)
        .child(targetUid)
        .push();
    await notifRef.set({
      'fromUsername': currentUsername.isNotEmpty ? currentUsername : 'Ai đó',
      'action': AppConstants.actionFollow,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Bỏ theo dõi người dùng (Unfollow)
  /// Port từ ProfileFragment.handleFollowed() và FollowActivity.handleFollowed()
  Future<void> unfollowUser({
    required String currentUid,
    required String targetUid,
  }) async {
    // 1. Xóa khỏi following của current user
    await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(currentUid)
        .collection('following')
        .doc(targetUid)
        .delete();

    // 2. Xóa khỏi followers của target user
    await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(targetUid)
        .collection('followers')
        .doc(currentUid)
        .delete();

    // 3. Đồng bộ lại follow counts
    await syncFollowCounts(currentUid);
    await syncFollowCounts(targetUid);
  }

  /// Đồng bộ lại follow counts dựa vào số tài liệu trong subcollection
  /// Port từ ProfileFragment.syncFollowCounts() và FollowActivity.syncFollowCounts()
  Future<void> syncFollowCounts(String uid) async {
    final followersCountSnap = await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(uid)
        .collection('followers')
        .where(FieldPath.documentId, isNotEqualTo: 'dump')
        .count()
        .get();

    final followingCountSnap = await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(uid)
        .collection('following')
        .where(FieldPath.documentId, isNotEqualTo: 'dump')
        .count()
        .get();

    final followersCount = followersCountSnap.count ?? 0;
    final followingCount = followingCountSnap.count ?? 0;

    await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(uid)
        .update({
      'followers': followersCount,
      'following': followingCount,
    });
  }

  /// Lấy danh sách Followers (người theo dõi)
  /// Port từ FollowersListFragment.java
  Future<List<ProfileModel>> getFollowers(String uid) async {
    final snap = await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(uid)
        .collection('followers')
        .get();

    final ids = snap.docs.map((doc) => doc.id).where((id) => id != 'dump').toList();
    if (ids.isEmpty) return [];

    final profiles = <ProfileModel>[];
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final querySnap = await _firestore
          .collection(AppConstants.profilesCollection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      profiles.addAll(querySnap.docs.map((doc) => ProfileModel.fromMap(doc.data())));
    }
    return profiles;
  }

  /// Lấy danh sách Following (đang theo dõi)
  /// Port từ FollowingListFragment.java
  Future<List<ProfileModel>> getFollowing(String uid) async {
    final snap = await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(uid)
        .collection('following')
        .get();

    final ids = snap.docs.map((doc) => doc.id).where((id) => id != 'dump').toList();
    if (ids.isEmpty) return [];

    final profiles = <ProfileModel>[];
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final querySnap = await _firestore
          .collection(AppConstants.profilesCollection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      profiles.addAll(querySnap.docs.map((doc) => ProfileModel.fromMap(doc.data())));
    }
    return profiles;
  }
}
