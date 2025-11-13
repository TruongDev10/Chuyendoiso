<h2 align="center">
    <a href="https://dainam.edu.vn/vi/khoa-cong-nghe-thong-tin">
    🎓 Faculty of Information Technology (DaiNam University)
    </a>
</h2>

<h2 align="center">
   💰 ỨNG DỤNG PHÂN TÍCH DỮ LIỆU & AI TRONG QUẢN LÝ CHI TIÊU & TIẾT KIỆM CHO SINH VIÊN
</h2>

<div align="center">
    <p align="center">
        <img src="docs/aiotlab_logo.png" alt="AIoTLab Logo" width="170"/>
        <img src="docs/fitdnu_logo.png" alt="FIT Logo" width="180"/>
        <img src="docs/dnu_logo.png" alt="DaiNam University Logo" width="200"/>
    </p>

[![AIoTLab](https://img.shields.io/badge/AIoTLab-green?style=for-the-badge)](https://www.facebook.com/DNUAIoTLab)
[![Faculty of Information Technology](https://img.shields.io/badge/Faculty%20of%20Information%20Technology-blue?style=for-the-badge)](https://dainam.edu.vn/vi/khoa-cong-nghe-thong-tin)
[![DaiNam University](https://img.shields.io/badge/DaiNam%20University-orange?style=for-the-badge)](https://dainam.edu.vn)

</div>

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
