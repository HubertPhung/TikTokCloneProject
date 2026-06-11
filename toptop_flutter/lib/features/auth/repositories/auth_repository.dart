// ignore_for_file: prefer_initializing_formals

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';

/// Repository xử lý logic xác thực và quản lý user/profile
/// Port từ EmailSignupActivity.java, EmailLogInActivity.java
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  /// Người dùng hiện tại
  User? get currentUser => _auth.currentUser;

  /// Stream trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng ký tài khoản mới bằng email + password
  /// Port từ EmailSignupActivity.setupUserDataAndProfile()
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    // Tạo tài khoản Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Lỗi xác thực người dùng mới.');
    }

    // Tạo username từ email handle
    String username = email.split('@')[0];
    username = username.replaceAll(RegExp(r'[^a-zA-Z0-9_.]'), '');
    if (username.isEmpty) {
      username = 'user_${user.uid.substring(0, 5)}';
    }

    // Tạo document trong collection "users"
    final userModel = UserModel(
      userId: user.uid,
      username: username,
      email: email,
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(userModel.toMap());

    // Tạo document trong collection "profiles"
    final profileModel = ProfileModel(
      userId: user.uid,
      username: username,
      fullname: username,
    );

    await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(user.uid)
        .set(profileModel.toMap());

    return user;
  }

  /// Đăng nhập bằng email + password
  /// Port từ EmailLogInActivity.loginUserAccount()
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Đăng nhập thất bại.');
    }

    return user;
  }

  /// Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Lấy thông tin user từ Firestore
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Lấy thông tin profile từ Firestore
  Future<ProfileModel?> getProfile(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.profilesCollection)
        .doc(uid)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return ProfileModel.fromMap(doc.data()!);
  }

  /// Stream theo dõi trạng thái user (kiểm tra banned)
  /// Port từ HomeScreenActivity.onStart() listener
  Stream<UserModel?> watchUserStatus(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }
}
