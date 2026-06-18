# 📋 Test Plan — TopTop Flutter App

---

## 1. Thông tin dự án

| Mục | Nội dung |
|---|---|
| **Project** | TopTop |
| **Platform** | Android, iOS |
| **Framework** | Flutter |
| **Database** | Firebase Firestore & Realtime Database |
| **Tester** | Nhóm phát triển |
| **Version** | 1.0 |
| **Ngày tạo** | 2026-06-18 |

---

## 2. Mục tiêu

Đảm bảo ứng dụng TopTop đáp ứng đầy đủ các tiêu chí sau:

- ✅ **Chức năng** hoạt động đúng theo yêu cầu nghiệp vụ
- ✅ **Không có lỗi nghiêm trọng** (Critical/High Severity bugs)
- ✅ **Giao diện** hiển thị đúng trên các kích thước màn hình
- ✅ **Firebase API** ổn định và xử lý lỗi an toàn
- ✅ **Hiệu năng** đạt ngưỡng chấp nhận được (60 FPS, RAM < 500 MB)

---

## 3. Phạm vi Testing

```
Authentication      Video           Profile         Advertisement
├── Login           ├── Upload      ├── Edit Profile ├── Sponsored Video
├── Register        ├── Delete      ├── Change Avatar └── Auto Play Ads
├── Logout          ├── Like        └── (future)
└── Forgot Password ├── Comment
                    └── Auto Play
Theme
├── Light Mode
└── Dark Mode
```

---

## 4. Test Case Sheet

### 🔐 Module Authentication

| ID | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| AUTH_01 | Login Success | Nhập email + password đúng → nhấn Đăng nhập | Đăng nhập thành công, chuyển sang Home Feed | High |
| AUTH_02 | Wrong Password | Nhập sai password → nhấn Đăng nhập | Hiển thị thông báo lỗi xác thực | High |
| AUTH_03 | Empty Email | Để trống trường email → nhấn Đăng nhập | Hiển thị validation "Vui lòng nhập email" | Medium |
| AUTH_04 | Empty Password | Để trống trường password → nhấn Đăng nhập | Hiển thị validation "Vui lòng nhập mật khẩu" | Medium |
| AUTH_05 | Logout | Vào Cài đặt → nhấn Đăng xuất → xác nhận | Quay về màn hình Đăng nhập | High |

---

### 📝 Module Register

| ID | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| REG_01 | Register Success | Nhập email mới + password hợp lệ (≥6 ký tự) → Đăng ký | Tạo tài khoản thành công, tự động đăng nhập | High |
| REG_02 | Email Already Exists | Nhập email đã tồn tại trong hệ thống → Đăng ký | Hiển thị lỗi "Email đã được sử dụng" | High |
| REG_03 | Weak Password | Nhập password < 6 ký tự → Đăng ký | Hiển thị lỗi "Mật khẩu cần ít nhất 6 ký tự" | Medium |

---

### 🎬 Module Video

| ID | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| VID_01 | Upload Video | Chọn video từ thư viện → nhập mô tả → nhấn Đăng | Upload thành công, video xuất hiện trên Feed | High |
| VID_02 | Upload Large File | Chọn video vượt giới hạn dung lượng → Upload | Hiển thị thông báo lỗi dung lượng | Medium |
| VID_03 | Delete Video | Vào trang cá nhân → nhấn giữ video → Xóa | Video biến mất khỏi profile và Feed | High |
| VID_04 | Play Video | Mở ứng dụng → vào Home Feed | Video tự động phát, âm thanh phát | High |
| VID_05 | Auto Play Next Video | Vuốt xuống trong Feed | Video kế tiếp tự động phát, video trước dừng | High |

---

### ❤️ Module Like

| ID | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| LIKE_01 | Like Video | Nhấn biểu tượng Tim trên video | Số Like tăng thêm 1, tim chuyển màu đỏ | High |
| LIKE_02 | Unlike Video | Nhấn lại biểu tượng Tim đã đỏ | Số Like giảm 1, tim về màu trắng | High |

---

### 💬 Module Comment

| ID | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| COM_01 | Add Comment | Mở phần bình luận → nhập nội dung → gửi | Bình luận xuất hiện ngay trong danh sách | High |
| COM_02 | Empty Comment | Mở bình luận → không nhập gì → nhấn Gửi | Nút Gửi bị vô hiệu hóa hoặc hiển thị lỗi | Medium |
| COM_03 | Delete Comment | Nhấn giữ bình luận của mình → Xóa | Bình luận biến mất khỏi danh sách | High |

---

### 👤 Module Profile

| ID | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| PRO_01 | Edit Display Name | Vào Chỉnh sửa hồ sơ → sửa tên → Lưu | Tên mới hiển thị trên trang cá nhân và Video Feed | High |
| PRO_02 | Change Avatar | Vào Chỉnh sửa hồ sơ → Chọn ảnh mới → Lưu | Avatar mới hiển thị trên toàn ứng dụng | High |
| PRO_03 | Long Username | Nhập username > 50 ký tự → Lưu | Hiển thị thông báo lỗi giới hạn ký tự | Low |

---

### 🎨 Module Theme

| ID | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| THEME_01 | Switch to Dark Mode | Vào Cài đặt → Màn hình → Chọn **Tối** | Toàn bộ UI chuyển sang giao diện tối (dark) | Medium |
| THEME_02 | Switch to Light Mode | Vào Cài đặt → Màn hình → Chọn **Sáng** | Toàn bộ UI chuyển sang giao diện sáng (light) | Medium |
| THEME_03 | Persist Theme on Restart | Chọn theme → Đóng app → Mở lại | Theme đã chọn vẫn được giữ nguyên | Medium |

---

### 📢 Module Sponsored Video (Advertisement)

| ID | Test Case | Steps | Expected Result | Priority |
|---|---|---|---|---|
| AD_01 | Show Sponsored Video | Lướt Feed qua ≥5 video | Hiển thị video với nhãn **Sponsored** / **Quảng cáo** | Medium |
| AD_02 | Click Sponsored Video | Nhấn vào nút kêu gọi hành động (CTA) của video quảng cáo | Điều hướng đúng đến trang/liên kết đích | Medium |
| AD_03 | Report Sponsored Video | Nhấn Report trên video quảng cáo → chọn lý do → Gửi | Gửi báo cáo thành công, hiển thị xác nhận | Low |

---

## 5. UI Testing Checklist

### 📱 Responsive — Kích thước màn hình

| Kích thước | Trạng thái | Ghi chú |
|---|---|---|
| 5.5 inch (e.g. Galaxy S8) | `[ ]` Pass / `[ ]` Fail | |
| 6.1 inch (e.g. Pixel 7) | `[ ]` Pass / `[ ]` Fail | |
| 6.7 inch (e.g. Galaxy S22 Ultra) | `[ ]` Pass / `[ ]` Fail | |
| Tablet (≥ 10 inch) | `[ ]` Pass / `[ ]` Fail | |

### 🎨 Theme Rendering

| Kiểm tra | Trạng thái |
|---|---|
| Light Mode hiển thị đúng màu sắc | `[ ]` |
| Dark Mode hiển thị đúng màu sắc | `[ ]` |

### 🔤 Text & Layout

| Kiểm tra | Trạng thái |
|---|---|
| Không có text bị tràn ra ngoài container | `[ ]` |
| Text không bị che bởi bàn phím khi nhập liệu | `[ ]` |

### 🧭 Navigation

| Kiểm tra | Trạng thái |
|---|---|
| Nút Back / Swipe Back hoạt động đúng | `[ ]` |
| Bottom Navigation Bar chuyển tab chính xác | `[ ]` |

---

## 6. Performance Checklist

### 🎥 Video Playback

| Tiêu chí | Ngưỡng | Trạng thái |
|---|---|---|
| Thời gian tải video đầu tiên | < 3 giây | `[ ]` |
| Không bị giật lag khi vuốt chuyển video | Mượt mà | `[ ]` |

### 🧠 Bộ nhớ (Memory)

| Tiêu chí | Ngưỡng | Trạng thái |
|---|---|---|
| Không có memory leak khi điều hướng lâu | 0 leak | `[ ]` |
| RAM sử dụng sau 10 phút sử dụng | < 500 MB | `[ ]` |

### 📊 Hiệu năng Đồ họa

| Tiêu chí | Ngưỡng | Trạng thái |
|---|---|---|
| Tốc độ khung hình (FPS) khi lướt Feed | 60 FPS | `[ ]` |

---

## 7. Security Checklist

| Kiểm tra bảo mật | Trạng thái | Ghi chú |
|---|---|---|
| Người dùng chưa đăng nhập **không thể** upload video | `[ ]` | Chuyển hướng sang màn hình Đăng nhập |
| Người dùng **không thể** chỉnh sửa profile của người khác | `[ ]` | Kiểm tra bằng cách truy cập trực tiếp route |
| Firebase Realtime Database Rules hoạt động đúng | `[ ]` | `"auth != null"` để read/write |
| Xử lý token hết hạn một cách chính xác | `[ ]` | Tự động đăng xuất hoặc refresh token |

---

## 8. Defect Report Template

> Sử dụng bảng này để ghi nhận các bug phát hiện trong quá trình kiểm thử.

| Bug ID | Severity | Module | Description | Steps to Reproduce | Status |
|---|---|---|---|---|---|
| BUG_001 | 🔴 High | Login | App crash khi đăng nhập với email hợp lệ | 1. Mở app → 2. Nhập email/pass → 3. Nhấn Đăng nhập | Open |
| BUG_002 | 🟡 Medium | Upload | Upload thất bại khi mất kết nối mạng giữa chừng | 1. Bắt đầu upload → 2. Tắt WiFi → 3. Quan sát | Fixed |
| BUG_003 | 🟢 Low | UI | Text username bị tràn trên màn hình nhỏ | 1. Dùng username dài → 2. Vào profile | Open |

### Mức độ Severity

| Level | Mô tả |
|---|---|
| 🔴 **Critical** | App crash, mất dữ liệu người dùng |
| 🔴 **High** | Chức năng chính không hoạt động |
| 🟡 **Medium** | Chức năng phụ bị ảnh hưởng, có cách workaround |
| 🟢 **Low** | Lỗi UI nhỏ, cosmetic issues |

---

> **Ghi chú:** Tài liệu này sẽ được cập nhật liên tục trong quá trình testing. Mọi bug mới phát hiện cần được thêm vào bảng Defect Report với đầy đủ thông tin.
