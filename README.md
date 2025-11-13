# 💰 Ứng dụng Phân tích Dữ liệu & AI trong Quản lý Chi tiêu & Tiết kiệm cho Sinh viên

## 📖 Giới thiệu

Ứng dụng di động thông minh hỗ trợ **sinh viên quản lý tài chính cá nhân** một cách hiệu quả.  
Người dùng có thể **ghi chép thu chi**, **phân tích chi tiêu**, và **lên kế hoạch tiết kiệm**, đồng thời được **AI Chatbot** hỗ trợ tư vấn tài chính cá nhân hóa.

Hệ thống kết hợp:
- **Phân tích dữ liệu (Data Analytics)** để thống kê và đánh giá chi tiêu.
- **Trí tuệ nhân tạo (AI)** để phân loại giao dịch tự động và gợi ý kế hoạch tài chính hợp lý.

---

## 🚀 Tính năng chính

| Nhóm tính năng | Mô tả |
|----------------|-------|
| 🔐 **Quản lý tài khoản** | Đăng ký / Đăng nhập bảo mật bằng JWT. |
| 💸 **Ghi chép thu chi** | Thêm, sửa, xóa giao dịch. AI (Naive Bayes) tự động gợi ý danh mục. |
| 📊 **Báo cáo thống kê** | Biểu đồ trực quan (Pie Chart, Bar Chart) thể hiện tình hình tài chính. |
| 🎯 **Mục tiêu tiết kiệm** | Thiết lập, theo dõi tiến độ tiết kiệm cá nhân. |
| 🤖 **AI Chatbot** | Trợ lý tài chính ảo (RASA) gợi ý chi tiêu, cảnh báo vượt ngân sách. |

---

## 🛠 Yêu cầu hệ thống (Prerequisites)

Trước khi cài đặt, đảm bảo bạn đã cài:

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Python 3.8 – 3.10](https://www.python.org/downloads/)
- [PostgreSQL](https://www.postgresql.org/download/)
- [Git](https://git-scm.com/downloads)

---

## ⚙️ Hướng dẫn Cài đặt & Chạy

### 🧩 1. Clone dự án

```bash
git clone https://github.com/username/ten-repo-cua-ban.git
cd ten-repo-cua-ban
```

---

### 🐍 2. Cài đặt Backend (Flask + PostgreSQL)

**📁 Thư mục:** `/backend`

#### Tạo môi trường ảo
```bash
cd backend
python -m venv venv
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate
```

#### Cài đặt thư viện
```bash
pip install -r requirements.txt
```

#### Cấu hình cơ sở dữ liệu
Tạo **database** trong PostgreSQL (ví dụ: `student_finance_db`).

Tạo file `.env` trong thư mục `backend`:

```env
DB_HOST=localhost
DB_NAME=student_finance_db
DB_USER=postgres
DB_PASS=password_cua_ban
SECRET_KEY=your_secret_key
```

#### Chạy migration và server
```bash
flask db upgrade
flask run
```

---

### 🧠 3. Cài đặt & Chạy AI Chatbot (RASA)

**📁 Thư mục:** `/ai_chatbot`

#### Cài đặt môi trường và thư viện
```bash
cd ai_chatbot
pip install -r requirements.txt
```

#### Huấn luyện mô hình
```bash
rasa train
```

#### Chạy Action Server
```bash
rasa run actions
```

#### Chạy RASA Core (API)
Mở terminal mới:
```bash
rasa run --enable-api --cors "*"
```

---

### 📱 4. Cài đặt & Chạy Ứng dụng Di động (Flutter)

**📁 Thư mục:** `/mobile_app`

#### Cài đặt dependencies
```bash
cd mobile_app
flutter pub get
```

#### Cấu hình endpoint API
Mở file `lib/constants.dart` (hoặc `.env`) và chỉnh:

```dart
const String API_URL = "http://192.168.1.x:5000"; // IP máy backend
```

> 💡 Dùng IP mạng LAN nếu chạy trên điện thoại thật hoặc emulator.

#### Chạy ứng dụng
```bash
flutter run
```

---

## 📂 Cấu trúc thư mục (Project Structure)

```
├── mobile_app/        # Ứng dụng Flutter (Frontend)
├── backend/           # Flask API & Database Models
├── ai_chatbot/        # Cấu hình & dữ liệu RASA (AI Chatbot)
├── docs/              # Tài liệu báo cáo, biểu đồ, thiết kế
└── README.md          # Hướng dẫn sử dụng
```

---

## 🧑‍💻 Công nghệ sử dụng

| Thành phần | Công nghệ |
|-------------|------------|
| Frontend | Flutter (Dart) |
| Backend | Python Flask |
| Database | PostgreSQL |
| AI Chatbot | RASA NLU + RASA Core |
| Data Analysis | Pandas, Scikit-learn |
| Authentication | JWT Token |

---

## 👥 Tác giả

**Nhóm 6 – CNTT 16-03**  
🎓 Trường Đại học Đại Nam  

👨‍💻 **Thành viên:**
- Nguyễn Danh Phóng  
- Bùi Văn Trường  

---
