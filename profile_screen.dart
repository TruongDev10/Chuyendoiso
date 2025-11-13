import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quanlytaichinh/services/firebase_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      // SỬA: Sử dụng Provider để lấy FirebaseService thay vì tạo instance mới
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      await firebaseService.signOut();

      // SỬA: Kiểm tra context có mounted trước khi navigation
      if (context.mounted) {
        // Navigation sẽ tự động xử lý bởi AuthWrapper
        // Không cần Navigator.push vì AuthWrapper sẽ tự chuyển
      }
    } catch (e) {
      // SỬA: Kiểm tra context có mounted trước khi showSnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng xuất: $e')),
        );
      }
      print('Logout error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hồ sơ cá nhân"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF009E60),
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              user?.displayName ?? "Người dùng",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? "Chưa có email",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Thông tin tài khoản
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.blue),
                    title: const Text("Email"),
                    subtitle: Text(user?.email ?? "Chưa có email"),
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.verified_user, color: Colors.green),
                    title: const Text("Trạng thái"),
                    subtitle: Text(user?.emailVerified == true
                        ? "Đã xác thực"
                        : "Chưa xác thực"),
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.calendar_today, color: Colors.orange),
                    title: const Text("Tham gia"),
                    subtitle: Text(user?.metadata.creationTime != null
                        ? "Từ ${DateTime.now().difference(user!.metadata.creationTime!).inDays} ngày trước"
                        : "Không rõ"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Nút đăng xuất
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: const Text("Đăng xuất"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
