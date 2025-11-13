import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import '../services/firebase_service.dart';
import 'add_transaction_screen.dart';
import 'category_detail_screen.dart';
import 'savings_goals_screen.dart';
import 'financial_reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebase = FirebaseService();
  final TextEditingController _budgetController = TextEditingController();

  double totalIncome = 0;
  double totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _listenSummary();
  }

  void _listenSummary() {
    final user = _firebase.currentUser;
    if (user != null) {
      _firebase.streamUserTransactions(user.uid).listen((snapshot) {
        double income = 0, expense = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] is num)
              ? (data['amount'] as num).toDouble()
              : double.tryParse(data['amount'].toString()) ?? 0.0;
          if (data['type'] == 'income') {
            income += amount;
          } else {
            expense += amount;
          }
        }
        setState(() {
          totalIncome = income;
          totalExpense = expense;
        });
      });
    }
  }

  // 🎯 TÍNH NĂNG MỚI: ĐẶT NGÂN SÁCH CHO HŨ
  void _setupBudgetForCategory(String categoryName) async {
    _budgetController.clear();

    final currentBudget = await _firebase.getCategoryBudget(categoryName).first;
    if (currentBudget != null) {
      _budgetController.text = currentBudget.toStringAsFixed(0);
    }

    final budget = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đặt ngân sách cho $categoryName'),
        content: TextFormField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Nhập số tiền',
            suffixText: 'đ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(_budgetController.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Lưu ngân sách'),
          ),
        ],
      ),
    );

    if (budget != null) {
      await _firebase.setCategoryBudget(categoryName, budget);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Đã đặt ngân sách $categoryName: ${intl.NumberFormat.decimalPattern('vi_VN').format(budget)}đ'),
          ),
        );
      }
    }
  }

  // 🎯 XỬ LÝ NHẤN VÀO HŨ - CHUYỂN SANG MÀN HÌNH CHI TIẾT
  void _onCategoryTap(String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(categoryName: categoryName),
      ),
    );
  }

  // 🎯 TÍNH NĂNG MỚI: ĐIỀU HƯỚNG ĐẾN MỤC TIÊU TIẾT KIỆM
  void _navigateToSavingsGoals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()),
    );
  }

  // 🎯 TÍNH NĂNG MỚI: ĐIỀU HƯỚNG ĐẾN BÁO CÁO TÀI CHÍNH
  void _navigateToFinancialReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FinancialReportsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebase.currentUser;
    if (user == null) {
      return const Center(child: Text('Vui lòng đăng nhập lại.'));
    }

    final categories = [
      {'icon': Icons.shopping_bag, 'name': 'Mua sắm', 'color': Colors.orange},
      {'icon': Icons.savings, 'name': 'Tiết kiệm', 'color': Colors.blue},
      {'icon': Icons.work, 'name': 'Kinh doanh', 'color': Colors.pinkAccent},
      {'icon': Icons.home, 'name': 'Thuê nhà', 'color': Colors.teal},
      {'icon': Icons.fastfood, 'name': 'Ăn uống', 'color': Colors.green},
      {'icon': Icons.group, 'name': 'Chia sẻ', 'color': Colors.purpleAccent},
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSummaryCard(),
              const SizedBox(height: 25),

              // 🎯 THÊM NÚT MỤC TIÊU TIẾT KIỆM & BÁO CÁO
              _buildQuickActions(),
              const SizedBox(height: 25),

              _sectionTitle(context, "Hũ chi tiêu - Nhấn giữ để đặt ngân sách"),
              const SizedBox(height: 10),
              _buildCategoryGrid(categories),
              const SizedBox(height: 25),
              _sectionTitle(context, "Giao dịch gần đây"),
              const SizedBox(height: 10),
              _buildTransactionList(user),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
        backgroundColor: const Color(0xFF009E60),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // 🎯 WIDGET MỚI: QUICK ACTIONS
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _quickActionItem(
              icon: Icons.flag,
              title: 'Mục tiêu',
              color: Colors.blue,
              onTap: _navigateToSavingsGoals,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _quickActionItem(
              icon: Icons.analytics,
              title: 'Báo cáo',
              color: Colors.green,
              onTap: _navigateToFinancialReports,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF009E60),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.account_balance_wallet, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Quản lý chi tiêu",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ]),
              Row(
                children: [
                  // 🎯 SỬA NÚT NÀY THÀNH BÁO CÁO TÀI CHÍNH
                  IconButton(
                    icon: const Icon(Icons.analytics, color: Colors.white),
                    onPressed: _navigateToFinancialReports,
                  ),
                  const Icon(Icons.notifications, color: Colors.white),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Xin chào, Trường 👋",
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Cùng theo dõi chi tiêu mỗi ngày nhé!",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final balance = totalIncome - totalExpense;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem("Thu nhập", totalIncome, Colors.green),
          _summaryItem("Chi tiêu", totalExpense, Colors.redAccent),
          _summaryItem("Số dư", balance, Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, double amount, Color color) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 6),
        Text(
          "${intl.NumberFormat.decimalPattern('vi_VN').format(amount)} đ",
          style: TextStyle(
              color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(List categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final c = categories[i];
        return GestureDetector(
          onTap: () => _onCategoryTap(c['name']),
          onLongPress: () => _setupBudgetForCategory(c['name']),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: (c['color'] as Color).withOpacity(0.15),
                  child:
                      Icon(c['icon'] as IconData, color: c['color'] as Color),
                ),
                const SizedBox(height: 6),
                Text(c['name'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 12)),
                const SizedBox(height: 4),

                // PROGRESS BAR HIỂN THỊ NGÂN SÁCH
                StreamBuilder<double>(
                  stream: _firebase.getCategorySpending(c['name']),
                  builder: (context, spendingSnapshot) {
                    return StreamBuilder<double?>(
                      stream: _firebase.getCategoryBudget(c['name']),
                      builder: (context, budgetSnapshot) {
                        final spent = spendingSnapshot.data ?? 0;
                        final budget = budgetSnapshot.data;

                        if (budget == null || budget == 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Chưa đặt ngân sách',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        final percent = spent / budget;
                        final remaining = budget - spent;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: percent > 1 ? 1 : percent,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percent > 0.8 ? Colors.red : Colors.green,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${intl.NumberFormat.decimalPattern('vi_VN').format(remaining)}đ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      percent > 0.8 ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionList(user) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firebase.streamUserTransactions(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text("Chưa có giao dịch nào.",
                style: TextStyle(color: Colors.grey)),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isExpense = data['type'] == 'expense';
            final amount = intl.NumberFormat.decimalPattern('vi_VN')
                .format(data['amount'] ?? 0);

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
                title: Text(data['title'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(intl.DateFormat('dd/MM/yyyy').format(date)),
                    if (data['category'] != null)
                      Text(
                        data['category'].toString(),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
                trailing: Text(
                  "${isExpense ? '-' : '+'}$amount đ",
                  style: TextStyle(
                    color: isExpense ? Colors.redAccent : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onLongPress: () async {
                  await _firebase.deleteTransaction(docs[index].id);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
