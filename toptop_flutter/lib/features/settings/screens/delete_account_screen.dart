import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

/// Màn hình Xóa tài khoản
/// Port từ DeleteAccountActivity.java và SignInToDeleteActivity.java trong Android project
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// Thực hiện xóa tài khoản hoàn toàn
  Future<void> _deleteAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Không tìm thấy thông tin phiên đăng nhập.');
      }

      // 1. Re-authenticate để đảm bảo session mới (tránh lỗi requires-recent-login của Firebase)
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      final uid = user.uid;

      // 2. Xóa dữ liệu người dùng trong Firestore để giữ db sạch sẽ
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .delete();
      await FirebaseFirestore.instance
          .collection(AppConstants.profilesCollection)
          .doc(uid)
          .delete();

      // 3. Xóa tài khoản trên Firebase Auth
      await user.delete();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tài khoản của bạn đã được xóa thành công.'),
            duration: Duration(seconds: 3),
          ),
        );

        // Chuyển hướng về màn hình đăng nhập chính
        context.go('/auth');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      String errorMsg = 'Xóa tài khoản thất bại.';
      if (e.code == 'wrong-password') {
        errorMsg = 'Mật khẩu xác nhận không chính xác.';
      } else {
        errorMsg = 'Lỗi xóa tài khoản: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Xóa tài khoản',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFE2C55)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFE2C55),
                      size: 72,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bạn có chắc chắn muốn xóa tài khoản?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Hành động này không thể hoàn tác. Khi xóa tài khoản:\n'
                      '• Thông tin cá nhân và cài đặt của bạn sẽ bị hủy bỏ.\n'
                      '• Bạn sẽ không thể truy cập lại dữ liệu của tài khoản này.\n'
                      '• Các video đã đăng của bạn sẽ không còn hiển thị trên bảng tin công cộng.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      validator: Validators.validatePassword,
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu để xác nhận',
                        hintStyle: const TextStyle(color: AppTheme.textHint),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.textHint,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFE2C55),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E1E),
                            title: const Text('Xác nhận xóa vĩnh viễn', style: TextStyle(color: Colors.white)),
                            content: const Text(
                              'Bạn có thực sự muốn xóa vĩnh viễn tài khoản TopTop này? Tất cả dữ liệu sẽ biến mất.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFE2C55),
                                ),
                                onPressed: () {
                                  Navigator.pop(context); // Đóng popup xác nhận
                                  _deleteAccount(); // Thực hiện xóa
                                },
                                child: const Text('Xóa ngay', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text(
                        'Xóa tài khoản',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
