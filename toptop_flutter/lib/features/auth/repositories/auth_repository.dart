// ignore_for_file: prefer_initializing_formals

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  /// Đăng nhập bằng Google Account
  /// Port từ EmailSignInActivity.java
  Future<User?> signInWithGoogle() async {
    // 1. Kích hoạt luồng đăng nhập Google
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      return null; // Người dùng hủy bỏ chọn tài khoản
    }

    // 2. Lấy thông tin xác thực từ Google
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 3. Đăng nhập vào Firebase Auth bằng Google Credential
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw Exception('Đăng nhập bằng tài khoản Google thất bại.');
    }

    // 4. Kiểm tra xem user document đã tồn tại trên Firestore chưa
    final userDocRef = _firestore.collection(AppConstants.usersCollection).doc(user.uid);
    final userDoc = await userDocRef.get();

    String username = googleUser.displayName ?? '';
    if (username.isEmpty) {
      username = 'user_${user.uid.substring(0, 5)}';
    }
    // Loại bỏ ký tự đặc biệt để làm username hợp lệ
    username = username.replaceAll(RegExp(r'[^a-zA-Z0-9_.]'), '');

    if (!userDoc.exists) {
      // Tạo bản ghi mới nếu chưa có
      final userData = {
        'userId': user.uid,
        'username': username,
        'birthdate': '',
        'avatarUrl': googleUser.photoUrl ?? '',
        'email': googleUser.email,
        'isPrivate': false,
        'phone': '',
        'status': 'active',
        'role': 'user',
      };
      await userDocRef.set(userData);
    } else {
      // Nếu tài khoản đã tồn tại, kiểm tra xem có bị khóa (banned) hay không
      final status = userDoc.data()?['status'] as String?;
      if (status == 'banned') {
        await signOut();
        throw Exception('Tài khoản của bạn đã bị khóa do vi phạm tiêu chuẩn cộng đồng.');
      }
    }

    // 5. Kiểm tra hồ sơ (profile) đã tồn tại chưa
    final profileDocRef = _firestore.collection(AppConstants.profilesCollection).doc(user.uid);
    final profileDoc = await profileDocRef.get();

    if (!profileDoc.exists) {
      final profileData = {
        'userId': user.uid,
        'email': googleUser.email,
        'username': username,
        'fullname': googleUser.displayName ?? username,
        'avatar': googleUser.photoUrl ?? '',
        'bio': 'Toptop user',
        'followers': 0,
        'following': 0,
        'likes': 0,
        'isPrivate': false,
      };
      await profileDocRef.set(profileData);
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
