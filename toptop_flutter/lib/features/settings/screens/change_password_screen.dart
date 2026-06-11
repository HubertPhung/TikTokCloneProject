import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

/// Màn hình Thay đổi Mật khẩu (gồm 2 bước: nhập mật khẩu cũ và mật khẩu mới)
/// Port từ ChangePasswordActivity.java trong Android project
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isStepOne = true;
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Bước 1: Xác thực mật khẩu cũ bằng cách Re-authenticate với Firebase Auth
  Future<void> _verifyOldPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Không tìm thấy thông tin đăng nhập người dùng.');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _oldPasswordController.text,
      );

      // Thực hiện Re-authentication
      await user.reauthenticateWithCredential(credential);

      setState(() {
        _isStepOne = false;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      String errorMsg = 'Mật khẩu cũ không chính xác.';
      if (e.code == 'wrong-password') {
        errorMsg = 'Mật khẩu cũ không chính xác.';
      } else if (e.code == 'user-not-found') {
        errorMsg = 'Không tìm thấy tài khoản người dùng.';
      } else {
        errorMsg = 'Lỗi xác thực: ${e.message}';
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

  /// Bước 2: Cập nhật mật khẩu mới trên Firebase Auth & Firestore "users"
  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    final confirmError = Validators.validateConfirmPassword(confirmPass, newPass);
    if (confirmError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(confirmError)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Không tìm thấy phiên đăng nhập.');
      }

      // 1. Cập nhật mật khẩu trên Firebase Auth
      await user.updatePassword(newPass);

      // 2. Cập nhật mật khẩu dạng plaintext trong Firestore "users" để đồng bộ với ứng dụng Java
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({'password': newPass});

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thay đổi mật khẩu thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật mật khẩu: $e')),
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
          'Đổi mật khẩu',
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
                    if (_isStepOne) ...[
                      // Bước 1: Mật khẩu cũ
                      const Text(
                        'Xác nhận mật khẩu cũ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Để bảo mật tài khoản, trước tiên hãy xác nhận mật khẩu hiện tại của bạn.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _oldPasswordController,
                        obscureText: _obscureOld,
                        style: const TextStyle(color: Colors.white),
                        validator: Validators.validatePassword,
                        decoration: InputDecoration(
                          hintText: 'Nhập mật khẩu hiện tại',
                          hintStyle: const TextStyle(color: AppTheme.textHint),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureOld ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.textHint,
                            ),
                            onPressed: () => setState(() => _obscureOld = !_obscureOld),
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
                        onPressed: _verifyOldPassword,
                        child: const Text(
                          'Tiếp theo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Bước 2: Mật khẩu mới
                      const Text(
                        'Tạo mật khẩu mới',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mật khẩu phải dài ít nhất 6 ký tự.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        style: const TextStyle(color: Colors.white),
                        validator: Validators.validatePassword,
                        decoration: InputDecoration(
                          hintText: 'Mật khẩu mới',
                          hintStyle: const TextStyle(color: AppTheme.textHint),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.textHint,
                            ),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Xác nhận mật khẩu mới',
                          hintStyle: const TextStyle(color: AppTheme.textHint),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.textHint,
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
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
                        onPressed: _updatePassword,
                        child: const Text(
                          'Cập nhật mật khẩu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
