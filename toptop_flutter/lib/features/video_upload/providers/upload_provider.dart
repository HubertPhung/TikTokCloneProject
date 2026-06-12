import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../repositories/legacy_hashtag_fixer.dart';
import '../repositories/upload_repository.dart';
import '../services/gemini_service.dart';

/// Các trạng thái có thể có của tiến trình tải lên video
enum UploadStatus { idle, uploading, saving, success, error }

/// Lớp đại diện cho trạng thái hiện tại của tác vụ upload
class UploadState {
  final UploadStatus status;
  final double progress;
  final String? errorMessage;
  final String? videoUrl;

  UploadState({
    required this.status,
    this.progress = 0.0,
    this.errorMessage,
    this.videoUrl,
  });

  UploadState copyWith({
    UploadStatus? status,
    double? progress,
    String? errorMessage,
    String? videoUrl,
  }) {
    return UploadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}

/// Provider của GeminiService
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

/// Provider của UploadRepository
final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository(
    firestore: ref.watch(firestoreProvider),
  );
});

/// Provider của LegacyHashtagFixer
final legacyHashtagFixerProvider = Provider<LegacyHashtagFixer>((ref) {
  return LegacyHashtagFixer(
    firestore: ref.watch(firestoreProvider),
    geminiService: ref.watch(geminiServiceProvider),
  );
});

/// Bộ quản lý trạng thái tải lên video (UploadNotifier)
class UploadNotifier extends StateNotifier<UploadState> {
  final UploadRepository _repository;

  UploadNotifier(this._repository) : super(UploadState(status: UploadStatus.idle));

  /// Thực thi toàn bộ quy trình: Tải lên Cloudinary -> Lưu thông tin Firestore
  Future<bool> uploadAndSaveVideo({
    required String filePath,
    required String description,
    required String authorId,
    required String username,
    required List<String> hashtags,
    String? location,
    bool allowDownload = true,
    bool allowDuet = true,
    bool isCopyrightProtected = false,
  }) async {
    state = UploadState(status: UploadStatus.uploading, progress: 0.0);

    try {
      final videoId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // 1. Tải lên Cloudinary với theo dõi tiến độ
      final videoUrl = await _repository.uploadVideoToCloudinary(
        filePath: filePath,
        onProgress: (p) {
          state = UploadState(status: UploadStatus.uploading, progress: p);
        },
      );

      // 2. Chuyển trạng thái lưu Firestore
      state = state.copyWith(status: UploadStatus.saving);

      await _repository.saveVideoToFirestore(
        videoId: videoId,
        videoUrl: videoUrl,
        description: description,
        authorId: authorId,
        username: username,
        hashtags: hashtags,
        location: location,
        allowDownload: allowDownload,
        allowDuet: allowDuet,
        isCopyrightProtected: isCopyrightProtected,
      );

      // 3. Kết thúc thành công
      state = state.copyWith(status: UploadStatus.success, videoUrl: videoUrl);
      return true;
    } catch (e) {
      state = state.copyWith(status: UploadStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  /// Khởi tạo lại trạng thái upload
  void reset() {
    state = UploadState(status: UploadStatus.idle);
  }
}

/// Provider quản lý trạng thái tác vụ tải lên video
final uploadStateProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(ref.watch(uploadRepositoryProvider));
});
