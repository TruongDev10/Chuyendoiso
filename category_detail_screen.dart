import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import '../services/firebase_service.dart';
import 'add_transaction_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;

  const CategoryDetailScreen({Key? key, required this.categoryName})
      : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final FirebaseService _firebase = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final user = _firebase.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.categoryName)),
        body: const Center(child: Text('Vui lòng đăng nhập lại.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: const Color(0xFF009E60),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionScreen(
                      selectedCategory: widget.categoryName),
                ),
              );
              if (result == true) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // THỐNG KÊ DANH MỤC
          _buildCategoryStats(user.uid),
          const SizedBox(height: 16),

          // DANH SÁCH GIAO DỊCH
          Expanded(
            child: _buildTransactionList(user.uid),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats(String userId) {
    return StreamBuilder<QuerySnapshot>(
      // 🔥 SỬA LỖI: Thay transactions bằng streamUserTransactions
      stream: _firebase.streamUserTransactions(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        double totalIncome = 0;
        double totalExpense = 0;
        int transactionCount = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          // 🔥 THÊM: Lọc theo category
          if (data['category'] == widget.categoryName) {
            final amount = (data['amount'] is num)
                ? (data['amount'] as num).toDouble()
                : 0.0;
            if (data['type'] == 'income') {
              totalIncome += amount;
            } else {
              totalExpense += amount;
            }
            transactionCount++;
          }
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Thống kê ${widget.categoryName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Tổng thu', totalIncome, Colors.green),
                    _buildStatItem('Tổng chi', totalExpense, Colors.red),
                    _buildStatItem('Số giao dịch', transactionCount.toDouble(),
                        Colors.blue,
                        isCount: true),
                  ],
                ),
                const SizedBox(height: 8),
                // 🔥 THÊM: Hiển thị tổng số dư
                _buildNetAmount(totalIncome - totalExpense),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String title, double value, Color color,
      {bool isCount = false}) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          isCount
              ? value.toInt().toString()
              : '${intl.NumberFormat.decimalPattern('vi_VN').format(value)}đ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // 🔥 THÊM: Hiển thị số dư
  Widget _buildNetAmount(double netAmount) {
    final isPositive = netAmount >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Số dư: ${isPositive ? '+' : ''}${intl.NumberFormat.decimalPattern('vi_VN').format(netAmount)}đ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      // 🔥 SỬA LỖI: Thay transactions bằng streamUserTransactions
      stream: _firebase.streamUserTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // 🔥 SỬA: Lọc transactions theo category
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['category'] == widget.categoryName;
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Chưa có giao dịch nào',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  'Nhấn nút + để thêm giao dịch',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isExpense = data['type'] == 'expense';
            final amount = (data['amount'] is num)
                ? (data['amount'] as num).toDouble()
                : 0.0;
            final formattedAmount =
                intl.NumberFormat.decimalPattern('vi_VN').format(amount);

            DateTime date;
            if (data['date'] is Timestamp) {
              date = (data['date'] as Timestamp).toDate();
            } else {
              date = DateTime.tryParse(data['date']?.toString() ?? '') ??
                  DateTime.now();
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (isExpense ? Colors.redAccent : Colors.green)
                      .withOpacity(0.1),
                  child: Icon(
                    isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isExpense ? Colors.redAccent : Colors.green,
                  ),
                ),
                title: Text(
                  data['title']?.toString() ?? 'Không có tiêu đề',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(intl.DateFormat('dd/MM/yyyy').format(date)),
                    if (data['description'] != null &&
                        data['description'].toString().isNotEmpty)
                      Text(
                        data['description'].toString(),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: Text(
                  "${isExpense ? '-' : '+'}$formattedAmount đ",
                  style: TextStyle(
                    color: isExpense ? Colors.redAccent : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onLongPress: () => _showDeleteDialog(
                    docs[index].id, data['title']?.toString() ?? ''),
              ),
            );
          },
        );
      },
    );
  }

  // 🔥 THÊM: Hiển thị dialog xác nhận xóa
  void _showDeleteDialog(String docId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giao dịch'),
        content: Text('Bạn có chắc muốn xóa "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firebase.deleteTransaction(docId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa giao dịch'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
