# 📱 TopTop Flutter - Báo Cáo Tổng Hợp Các Sprints & Thay Đổi (Sprints Summary)

Tài liệu này tổng hợp toàn bộ quá trình di chuyển (migration) ứng dụng mạng xã hội video ngắn **TopTop** (TikTok Clone) từ Android Native (Java) sang **Flutter/Dart**, bao gồm tất cả các Sprint phát triển, nâng cấp UI/UX, tối ưu hiệu năng và đồng bộ hóa logic.

---

## 🗺️ Tóm tắt Kiến trúc (Architecture)
*   **Quản lý Trạng thái:** `Riverpod` (StateNotifierProvider, StreamProvider, FutureProvider) quản lý logic độc lập khỏi tầng giao diện.
*   **Luồng dữ liệu:** Kết nối thời gian thực với Firestore, Realtime DB, Cloud Storage và dịch vụ nén video của Cloudinary.
*   **Trí tuệ nhân tạo:** Tích hợp SDK Gemini AI gợi ý hashtag viral từ hình ảnh bìa.

---

## 🚀 Các Sprints đã thực hiện & Nội dung thay đổi

### 1. Sprints 1-6: Xây dựng nền tảng & Tính năng cốt lõi (Core Features)
*   **Authentication (Auth):** Đăng ký/đăng nhập qua Email + liên kết Google Sign-In với Firebase Auth.
*   **Video Feed:** Lướt video dọc không độ trễ bằng `PageView.builder` kết hợp `video_player`. Tự động lặp lại và tải trước (pre-caching).
*   **Profile:** Quản lý trang cá nhân, đổi ảnh đại diện (avatar), cập nhật tiểu sử (bio), follow/unfollow và hiển thị danh sách video.
*   **Comments:** Giao diện bình luận dạng cây phân cấp (bình luận gốc và phản hồi), tự động đồng bộ thời gian thực qua Firestore Stream.
*   **Search:** Tìm kiếm tài khoản người dùng theo từ khóa, tìm video theo hashtag (#tag), hiển thị các hashtag đang thịnh hành.
*   **Upload Video:** Chọn video từ thư viện hoặc quay từ camera -> Tải lên Cloudinary CDN -> Gọi API Gemini đề xuất hashtag tự động.
*   **Direct Chat:** Chat nhắn tin 2 chiều qua Realtime Database, hiển thị chỉ báo hoạt động online (pulsing green dot).
*   **Settings:** Thiết lập cá nhân, đổi mật khẩu và tính năng xóa tài khoản bảo mật.

---

### 2. Sprint 7: Nâng cấp Giao diện, Quảng cáo & Cài đặt bổ sung
*   **Light/Dark Theme:** Chuyển đổi linh hoạt chủ đề Sáng/Tối/Hệ thống thông qua `themeModeProvider` kết hợp lưu trữ lâu dài bằng `SharedPreferences`.
*   **Video Ads Integration:** Thiết kế cấu trúc đa hình `FeedItem` (`VideoItem` & `AdItem`). Ứng dụng tự động chèn xen kẽ 1 video quảng cáo kèm nút kêu gọi hành động (CTA) sau mỗi 5 video thường.
*   **Da Lat Tourism Campaign:** Tăng ưu tiên xếp hạng cho video thuộc chiến dịch Đà Lạt, tự động ghi nhận phân tích hành vi người dùng (Analytics) lên Firestore collection `campaign_analytics`.
*   **Bảo mật & Bản quyền (Privacy & Copyright):** Thêm 3 Switch điều khiển khi tải video lên: Cho phép tải xuống, Bảo vệ bản quyền, Tham gia chiến dịch Đà Lạt.
*   **Đồng bộ hóa ngày sinh:** Đọc ghi trường ngày sinh thực tế của Profile thay vì dùng dữ liệu giả định.

---

### 3. Sprint UI Polish: Thẩm mỹ cao cấp Premium (Premium Aesthetic)
*   **Splash Screen:** Hoạt ảnh logo pulsing glow phóng to/thu nhỏ nhịp tim kết hợp text shimmer bóng mờ.
*   **Auth & Choice Pages:** Thiết kế nền gradient tối, nút bấm gradient hồng neon rực rỡ, các hộp nhập liệu glow sáng viền khi focus.
*   **Navigation Shell:** Thêm hiệu ứng kính mờ (glassmorphism), đường viền mờ phía trên, nút tạo bài đăng (+) nổi bật với viền sáng cyan/pink, thanh active dot trượt mượt dưới tab đang chọn.
*   **Feed Interactions:** Thêm đĩa nhạc xoay tròn phát nhạc gốc, hiệu ứng vỡ tim bay (heart burst) scale nhanh khi người dùng double tap thích video.
*   **Grid & List Polish:** Bo góc các ảnh thumb, bổ sung hiệu ứng chuyển màu mờ cho chỉ số xem.

---

### 4. Sprint Code Optimization: Tối ưu hiệu năng & Tiết kiệm bộ nhớ (Performance Tuning)
*   **Tách nhỏ phạm vi vẽ lại (Granular Rebuilds):** Tách biệt các nút Like, Mute, bình luận trong [VideoActionBar](file:///d:/University/Mobile_Application/TopTop/toptop_flutter/lib/features/video_feed/widgets/video_action_bar.dart) vào các scope `Consumer` độc lập. Việc tương tác nút không gây vẽ lại (rebuild) toàn bộ trình xem video.
*   **Quản lý Vòng đời Video Player:** Tối ưu hóa việc gọi khởi tạo ExoPlayer, giải phóng tài nguyên bộ nhớ đệm ngay khi tắt màn hình, cô lập hoạt ảnh vẽ nhanh bằng `RepaintBoundary`.
*   **Giới hạn Bộ nhớ Đệm Ảnh (Image Cache Limits):** Cấu hình `memCacheWidth` và `maxWidth` (khoảng 80 - 250 pixels) cho toàn bộ widget `CachedNetworkImage` trong danh sách tìm kiếm, bình luận, avatar và lưới ảnh cá nhân. Ngăn ngừa triệt để lỗi tràn bộ nhớ (Out of Memory - OOM) trên thiết bị cấu hình thấp.

---

### 5. Sprint UI/UX Advanced Polish: Tương tác Xúc giác & Chuyển cảnh
*   **Phản hồi Xúc giác (Haptic Feedback):** Tích hợp hiệu ứng rung phản hồi vật lý nhẹ nhàng khi chuyển tab điều hướng, thích video, tắt/bật âm thanh.
*   **Bộ xương tải Shimmer (Shimmer Skeletons):** Tạo widget khung xương shimmer động cho Feed video, lưới video profile và danh sách Inbox chat thay thế cho vòng quay loading truyền thống.
*   **Cử chỉ vuốt chuyển trang nhanh:** Vuốt ngang từ phải sang trái trên video player để chuyển trực tiếp đến trang cá nhân của tác giả.
*   **Hoạt ảnh chuyển trang slide:** Áp dụng hiệu ứng trượt từ phải sang trái đồng bộ cho toàn bộ GoRouter navigation khi mở các trang chi tiết.

---

### 6. Sprint Profile Data & Logic Synchronization (Đồng bộ hóa dữ liệu & Logic)
Giải quyết vấn đề dữ liệu bị phân mảnh (denormalized) khi người dùng thay đổi thông tin cá nhân:
1.  **Đồng bộ phía Cơ sở dữ liệu (Firestore Sync):**
    *   Cập nhật logic [ProfileRepository.updateUsername](file:///d:/University/Mobile_Application/TopTop/toptop_flutter/lib/features/profile/repositories/profile_repository.dart#L90): Khi đổi username thành công ở profiles/users, hệ thống kích hoạt Firestore Batch writes tự động truy vấn và đổi trường `username` của mọi video lịch sử do người này đăng trong collection `videos`.
2.  **Đồng bộ phản ứng thời gian thực phía Giao diện (Reactive UI Sync):**
    *   Nâng cấp [VideoOverlay](file:///d:/University/Mobile_Application/TopTop/toptop_flutter/lib/features/video_feed/widgets/video_overlay.dart) sang lắng nghe phản ứng động từ [userProfileStreamProvider](file:///d:/University/Mobile_Application/TopTop/toptop_flutter/lib/features/profile/providers/profile_provider.dart#L18). Mọi cập nhật username sẽ hiển thị ngay lập tức lên trình phát video feed mà không bị phụ thuộc vào tốc độ ghi ghi dữ liệu hàng loạt dưới database.
    *   Cập nhật [VideoActionBar](file:///d:/University/Mobile_Application/TopTop/toptop_flutter/lib/features/video_feed/widgets/video_action_bar.dart) để theo dõi ảnh đại diện thông qua Stream của [userProfileStreamProvider](file:///d:/University/Mobile_Application/TopTop/toptop_flutter/lib/features/profile/providers/profile_provider.dart#L18) thay vì Future tĩnh, giúp avatar tác giả luôn khớp chính xác thời gian thực.
    *   Nhờ cơ chế Riverpod StreamProvider, danh sách chat trong Inbox, danh sách tìm kiếm và các dòng bình luận cũng tự động đồng bộ tức thời khi hồ sơ thay đổi.

---

## 🛠️ Trạng thái Xác minh & Chất lượng mã nguồn (Verification Status)
*   **Bộ phân tích mã nguồn:** Chạy `flutter analyze` đạt kết quả sạch hoàn toàn (**No issues found!**).
*   **Kiểm thử thủ công:** Đã kiểm tra tính ổn định trên giả lập Android: Đổi avatar/username -> kiểm tra feed video -> kiểm tra bình luận -> kiểm tra inbox chat đồng bộ tức thì không có độ trễ.
