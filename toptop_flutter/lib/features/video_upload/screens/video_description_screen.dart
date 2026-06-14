// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/upload_provider.dart';

/// Màn hình thêm mô tả video, gợi ý hashtag bằng AI và thực hiện tải lên Cloudinary
class VideoDescriptionScreen extends ConsumerStatefulWidget {
  final String? videoPath;
  final String? videoId; // Truyền vào nếu ở chế độ chỉnh sửa (Edit Mode)

  const VideoDescriptionScreen({
    super.key,
    this.videoPath,
    this.videoId,
  });

  @override
  ConsumerState<VideoDescriptionScreen> createState() => _VideoDescriptionScreenState();
}

class _VideoDescriptionScreenState extends ConsumerState<VideoDescriptionScreen> {
  final TextEditingController _descController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  VideoPlayerController? _videoPlayerController;
  bool _isEditMode = false;
  bool _isAiLoading = false;
  String _previewUrl = '';
  
  // Trạng thái bảo mật và chiến dịch Đà Lạt
  bool _allowDownload = true;
  bool _isCopyrightProtected = false;
  bool _isDalatCampaign = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.videoId != null && widget.videoId!.isNotEmpty;
    
    if (_isEditMode) {
      _loadVideoDetails();
    } else if (widget.videoPath != null && widget.videoPath!.isNotEmpty) {
      _initLocalVideoPlayer();
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _focusNode.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  /// Tải thông tin video cũ khi ở chế độ Edit
  Future<void> _loadVideoDetails() async {
    final firestore = ref.read(firestoreProvider);
    final doc = await firestore.collection('videos').doc(widget.videoId).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        _descController.text = data['description'] as String? ?? '';
        final videoUri = data['videoUri'] as String? ?? '';
        if (videoUri.isNotEmpty) {
          setState(() {
            _previewUrl = videoUri.replaceAll('.mp4', '.jpg');
            if (_previewUrl.contains('/upload/')) {
              _previewUrl = _previewUrl.replaceAll('/upload/', '/upload/so_0/');
            }
          });
        }
      }
    }
  }

  /// Khởi chạy trình xem trước video cục bộ
  Future<void> _initLocalVideoPlayer() async {
    final file = File(widget.videoPath!);
    if (await file.exists()) {
      _videoPlayerController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {});
          _videoPlayerController?.setLooping(true);
          _videoPlayerController?.play();
          _videoPlayerController?.setVolume(0.0); // Mute preview
        });
    }
  }

  /// Thêm ký tự `#` hoặc ` #` vào vị trí con trỏ trong ô nhập
  void _insertHashtagSymbol() {
    final text = _descController.text;
    final selection = _descController.selection;
    final cursor = selection.start;
    
    String hashtag = '#';
    // Thêm khoảng trắng phía trước nếu ký tự trước đó không phải khoảng trắng
    if (cursor > 0 && text[cursor - 1] != ' ') {
      hashtag = ' #';
    }

    final newText = text.replaceRange(
      selection.start == -1 ? text.length : selection.start,
      selection.end == -1 ? text.length : selection.end,
      hashtag,
    );

    _descController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (selection.start == -1 ? text.length : selection.start) + hashtag.length,
      ),
    );
    _focusNode.requestFocus();
  }

  /// Gọi Gemini AI gợi ý hashtag dựa trên mô tả hoặc hình ảnh bìa
  Future<void> _suggestHashtags() async {
    setState(() {
      _isAiLoading = true;
    });

    try {
      final gemini = ref.read(geminiServiceProvider);
      String aiResult = '';

      if (_isEditMode && _previewUrl.isNotEmpty) {
        // Lấy bytes ảnh từ Cloudinary để phân tích trực quan bằng AI
        final response = await http.get(Uri.parse(_previewUrl));
        if (response.statusCode == 200) {
          aiResult = await gemini.suggestHashtags(response.bodyBytes);
        }
      } 
      
      // Fallback nếu rỗng hoặc ở chế độ upload mới (gợi ý dựa trên từ khóa văn bản)
      if (aiResult.isEmpty) {
        final currentText = _descController.text.trim();
        final textPrompt = currentText.isNotEmpty
            ? 'Hãy gợi ý 5-10 hashtag TikTok tiếng Việt viral liên quan đến mô tả: "$currentText". Chỉ trả về các hashtag cách nhau bởi dấu cách.'
            : 'Hãy gợi ý 5-10 hashtag TikTok tiếng Việt đang thịnh hành (viral) nhất hiện nay. Chỉ trả về các hashtag cách nhau bởi dấu cách.';
            
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: AppConstants.geminiApiKey,
        );
        final response = await model.generateContent([Content.text(textPrompt)]);
        aiResult = response.text ?? '';
      }

      if (aiResult.isNotEmpty && mounted) {
        final currentText = _descController.text;
        final spacing = (currentText.isEmpty || currentText.endsWith(' ')) ? '' : ' ';
        _descController.text = '$currentText$spacing${aiResult.trim()}';
        _descController.selection = TextSelection.collapsed(
          offset: _descController.text.length,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gợi ý AI: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiLoading = false;
        });
      }
    }
  }

  /// Xử lý cập nhật thông tin video ở chế độ Edit
  Future<void> _handleUpdate() async {
    final description = _descController.text.trim();
    
    // Tách các hashtag từ nội dung mô tả
    final List<String> hashtagsList = [];
    final matches = RegExp(r'#([A-Za-z0-9_\u00C0-\u1EF9-]+)').allMatches(description);
    for (final m in matches) {
      final tagText = m.group(1);
      if (tagText != null) {
        hashtagsList.add(tagText.toLowerCase());
      }
    }

    final firestore = ref.read(firestoreProvider);
    final user = ref.read(currentUserProvider);

    if (user == null) return;

    setState(() {
      _isAiLoading = true;
    });

    try {
      final updates = {
        'description': description,
        'hashtags': hashtagsList,
      };

      // 1. Cập nhật bảng videos
      await firestore.collection('videos').doc(widget.videoId).update(updates);

      // 2. Cập nhật bảng video_summaries
      await firestore.collection('video_summaries').doc(widget.videoId).update(updates);

      // 3. Cập nhật bảng mirror của user
      await firestore
          .collection('profiles')
          .doc(user.uid)
          .collection('public_videos')
          .doc(widget.videoId)
          .update(updates);

      // 4. Xóa hashtag cũ và thêm mới
      final hashtagsQuery = await firestore
          .collection('hashtags')
          .where('videoId', isEqualTo: widget.videoId)
          .get();

      final batch = firestore.batch();
      for (final doc in hashtagsQuery.docs) {
        batch.delete(doc.reference);
      }

      for (final tag in hashtagsList) {
        final newTagRef = firestore.collection('hashtags').doc();
        batch.set(newTagRef, {
          'hashtag': tag,
          'videoId': widget.videoId,
          'thumbnailUri': _previewUrl,
        });
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật video thành công!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiLoading = false;
        });
      }
    }
  }

  /// Xử lý đăng tải video mới
  Future<void> _handlePublish() async {
    if (widget.videoPath == null || widget.videoPath!.isEmpty) return;

    final user = ref.read(currentUserProvider);
    final userProfile = ref.read(currentUserProfileProvider).valueOrNull;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đăng video!')),
      );
      return;
    }

    final description = _descController.text.trim();
    
    // Trích xuất hashtag
    final List<String> hashtagsList = [];
    final matches = RegExp(r'#([A-Za-z0-9_\u00C0-\u1EF9-]+)').allMatches(description);
    for (final m in matches) {
      final tagText = m.group(1);
      if (tagText != null) {
        hashtagsList.add(tagText.toLowerCase());
      }
    }

    final myUsername =
        userProfile?.username ?? user.email?.split('@')[0] ?? 'user';

    // Bắt đầu quy trình tải lên
    final uploadNotifier = ref.read(uploadStateProvider.notifier);
    
    // Hiển thị dialog tiến trình tải lên
    _showUploadProgressDialog();

    final success = await uploadNotifier.uploadAndSaveVideo(
      filePath: widget.videoPath!,
      description: description,
      authorId: user.uid,
      username: myUsername,
      hashtags: hashtagsList,
      location: _isDalatCampaign ? 'Da Lat' : null,
      allowDownload: _allowDownload,
      allowDuet: true,
      isCopyrightProtected: _isCopyrightProtected,
    );

    if (mounted) {
      Navigator.pop(context); // Đóng dialog tiến trình
    }

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng video thành công! Chờ duyệt.')),
        );
        // Reset state upload
        uploadNotifier.reset();
        context.go('/home');
      }
    } else {
      final err = ref.read(uploadStateProvider).errorMessage;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng video thất bại: $err')),
        );
      }
    }
  }

  /// Hiển thị Dialog theo dõi phần trăm tiến độ tải lên
  void _showUploadProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final uploadState = ref.watch(uploadStateProvider);
            final percent = (uploadState.progress * 100).toInt();

            String statusText = 'Đang chuẩn bị...';
            if (uploadState.status == UploadStatus.uploading) {
              statusText = 'Đang tải video lên: $percent%';
            } else if (uploadState.status == UploadStatus.saving) {
              statusText = 'Đang lưu dữ liệu video...';
            }

            return WillPopScope(
              onWillPop: () async => false, // Ngăn chặn tắt dialog
              child: AlertDialog(
                backgroundColor: const Color(0xFF1D1D1F),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      statusText,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    if (uploadState.status == UploadStatus.uploading)
                      LinearProgressIndicator(
                        value: uploadState.progress,
                        color: AppTheme.primaryColor,
                        backgroundColor: Colors.white10,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditMode ? 'Sửa thông tin video' : 'Mô tả video',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: _isAiLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        // Hộp nội dung và xem trước
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Ô xem trước video/ảnh bìa ở bên trái
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 100,
                                height: 150,
                                color: Colors.grey[900],
                                child: _isEditMode
                                    ? (_previewUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: _previewUrl,
                                            fit: BoxFit.cover,
                                            memCacheWidth: 200, // Tối ưu kích thước lưu cache bộ nhớ
                                            placeholder: (context, url) =>
                                                const Icon(Icons.image, color: Colors.white24),
                                            errorWidget: (context, url, error) =>
                                                const Icon(Icons.image, color: Colors.white24),
                                          )
                                        : const Icon(Icons.image, color: Colors.white24))
                                    : (_videoPlayerController != null &&
                                            _videoPlayerController!.value.isInitialized
                                        ? AspectRatio(
                                            aspectRatio: _videoPlayerController!.value.aspectRatio,
                                            child: VideoPlayer(_videoPlayerController!),
                                          )
                                        : const Icon(Icons.play_arrow, color: Colors.white24)),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // 2. Ô soạn thảo nội dung mô tả ở bên phải
                            Expanded(
                              child: TextField(
                                controller: _descController,
                                focusNode: _focusNode,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                maxLines: 6,
                                decoration: const InputDecoration(
                                  hintText: 'Nhập mô tả cho video của bạn ở đây...',
                                  hintStyle: TextStyle(color: AppTheme.textHint, fontSize: 13),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Hàng phím hỗ trợ nhập liệu
                        Row(
                          children: [
                            // Nút thêm phím # nhanh
                            OutlinedButton.icon(
                              onPressed: _insertHashtagSymbol,
                              icon: const Icon(Icons.tag, size: 16, color: Colors.white),
                              label: const Text('Thêm #', style: TextStyle(color: Colors.white, fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Nút gợi ý AI
                            ElevatedButton.icon(
                              onPressed: _suggestHashtags,
                              icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                              label: const Text('Gợi ý hashtag AI', style: TextStyle(color: Colors.white, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2B2B2D),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        // === Cài đặt quyền riêng tư & chiến dịch ===
                        const Text(
                          'Cài đặt quyền riêng tư',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Card container cho privacy switches
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Column(
                            children: [

                        // Cho phép tải xuống
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppTheme.primaryColor,
                          title: const Text(
                            'Cho phép tải xuống',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Người xem có thể lưu video này',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          secondary: const Icon(Icons.download_rounded, color: Colors.white70),
                          value: _allowDownload,
                          onChanged: (val) => setState(() => _allowDownload = val),
                        ),

                        const Divider(color: Colors.white12, height: 1),

                        // Bảo vệ bản quyền
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppTheme.primaryColor,
                          title: const Text(
                            'Bảo vệ bản quyền',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Đánh dấu video là nội dung gốc, được bảo vệ',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          secondary: const Icon(Icons.copyright_rounded, color: Colors.white70),
                          value: _isCopyrightProtected,
                          onChanged: (val) => setState(() => _isCopyrightProtected = val),
                        ),

                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          'Chiến dịch quảng bá',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Card container cho campaign
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Column(
                            children: [

                        // Chiến dịch Đà Lạt
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: const Color(0xFF4CAF50),
                          title: const Text(
                            '🌲 Đà Lạt Trong Tôi',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Tham gia chiến dịch quảng bá du lịch Đà Lạt để video được ưu tiên hiển thị',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          secondary: const Icon(Icons.eco_rounded, color: Color(0xFF4CAF50)),
                          value: _isDalatCampaign,
                          onChanged: (val) => setState(() => _isDalatCampaign = val),
                        ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nút hành động đăng/cập nhật cuối trang
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppTheme.brandGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isEditMode ? _handleUpdate : _handlePublish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isEditMode ? 'CẬP NHẬT VIDEO' : 'ĐĂNG VIDEO',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
