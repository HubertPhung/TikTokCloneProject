import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// Màn hình sửa đổi một trường thông tin riêng biệt (Username, Ngày sinh)
/// Port từ EditActivity.java
class EditFieldScreen extends ConsumerStatefulWidget {
  final String field;

  const EditFieldScreen({
    super.key,
    required this.field,
  });

  @override
  ConsumerState<EditFieldScreen> createState() => _EditFieldScreenState();
}

class _EditFieldScreenState extends ConsumerState<EditFieldScreen> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isModified = false;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    // Load dữ liệu hiện tại vào ô nhập
    Future.microtask(() async {
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      if (profile != null) {
        if (widget.field == 'username') {
          _controller.text = profile.username;
        } else if (widget.field == 'birthdate' && profile.birthdate.isNotEmpty) {
          _controller.text = profile.birthdate;
        }
      }
    });

    _controller.addListener(() {
      setState(() {
        _isModified = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Color(0xFF1D1D1F),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year;
      setState(() {
        _controller.text = "$day/$month/$year";
        _errorText = '';
      });
    }
  }

  Future<void> _saveField(String uid) async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isSaving = true;
      _errorText = '';
    });

    final repo = ref.read(profileRepositoryProvider);
    final value = _controller.text.trim();

    try {
      if (widget.field == 'username') {
        // 1. Kiểm tra định dạng
        final error = Validators.validateUsername(value);
        if (error != null) {
          setState(() {
            _errorText = error;
            _isSaving = false;
          });
          return;
        }

        // 2. Lưu (Repo tự kiểm tra trùng lặp trên Firestore)
        final success = await repo.updateUsername(uid: uid, newUsername: value);
        if (!success) {
          setState(() {
            _errorText = 'Username đã được sử dụng bởi tài khoản khác.';
            _isSaving = false;
          });
          return;
        }
      } else if (widget.field == 'birthdate') {
        // 1. Kiểm tra định dạng ngày sinh dd/mm/yyyy
        final error = Validators.validateBirthdate(value);
        if (error != null) {
          setState(() {
            _errorText = error;
            _isSaving = false;
          });
          return;
        }

        // 2. Lưu
        await repo.updateBirthdate(uid: uid, birthdate: value);
      }

      // 3. Làm mới auth profile
      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thông tin thành công!')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorText = 'Lỗi cập nhật: ${e.toString()}';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isUsername = widget.field == 'username';
    final title = isUsername ? 'Thay đổi Username' : 'Thay đổi ngày sinh';
    final label = isUsername ? 'Username' : 'Ngày sinh (DD/MM/YYYY)';

    final canSave = _isModified && _controller.text.isNotEmpty && !_isSaving;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: canSave && currentUser != null ? () => _saveField(currentUser.uid) : null,
            child: Text(
              'Lưu',
              style: TextStyle(
                color: canSave ? AppTheme.primaryColor : Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white30, fontSize: 12),
              ),
              const SizedBox(height: 8),

              // Ô nhập dữ liệu
              TextFormField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                keyboardType: isUsername ? TextInputType.text : TextInputType.datetime,
                decoration: InputDecoration(
                  hintText: isUsername ? 'Nhập username mới...' : '01/01/2000',
                  hintStyle: const TextStyle(color: Colors.white24),
                  suffixIcon: !isUsername
                      ? IconButton(
                          icon: const Icon(Icons.calendar_today, color: Colors.white54),
                          onPressed: () => _selectDate(context),
                        )
                      : null,
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Báo lỗi nếu có
              if (_errorText.isNotEmpty)
                Text(
                  _errorText,
                  style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13),
                ),

              const SizedBox(height: 24),

              // Mô tả điều khoản của Username giống TikTok
              if (isUsername)
                const Text(
                  'Username có thể chứa các chữ cái, chữ số, dấu gạch dưới, gạch ngang và dấu chấm. Việc thay đổi username sẽ làm thay đổi đường dẫn trang cá nhân của bạn.',
                  style: TextStyle(color: Colors.white30, fontSize: 13, height: 1.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
