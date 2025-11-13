import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({Key? key}) : super(key: key);

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  final FirebaseService _firebase = FirebaseService();
  final Uuid _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final user = _firebase.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mục tiêu tiết kiệm')),
        body: const Center(child: Text('Vui lòng đăng nhập lại.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mục tiêu tiết kiệm'),
        backgroundColor: const Color(0xFF009E60),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<SavingsGoal>>(
        stream: _firebase.streamUserSavingsGoals(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Có lỗi xảy ra',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final goals = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              return _buildGoalCard(goals[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: const Color(0xFF009E60),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Chưa có mục tiêu nào',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhấn nút + để tạo mục tiêu mới',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(SavingsGoal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getGoalIcon(goal.icon),
                  color: goal.color,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Hạn: ${intl.DateFormat('dd/MM/yyyy').format(goal.targetDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildProgressCircle(goal),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: goal.progress > 1 ? 1 : goal.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.progress >= 1 ? Colors.green : goal.color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${intl.NumberFormat.decimalPattern('vi_VN').format(goal.currentAmount)}đ / ${intl.NumberFormat.decimalPattern('vi_VN').format(goal.targetAmount)}đ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(goal.progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: goal.progress >= 1 ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),
            if (goal.daysRemaining > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Còn ${goal.daysRemaining} ngày - Cần tiết kiệm ${intl.NumberFormat.decimalPattern('vi_VN').format(goal.monthlySaving)}đ/tháng',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ] else if (goal.daysRemaining < 0) ...[
              const SizedBox(height: 8),
              Text(
                'Đã quá hạn ${-goal.daysRemaining} ngày',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[600],
                ),
              ),
            ],
            // 🔥 THÊM NÚT GÓP TIỀN
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddContributionDialog(goal),
                icon: const Icon(Icons.attach_money, size: 18),
                label: const Text('Góp tiền'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009E60),
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

  Widget _buildProgressCircle(SavingsGoal goal) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            value: goal.progress > 1 ? 1 : goal.progress,
            strokeWidth: 4,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              goal.progress >= 1 ? Colors.green : goal.color,
            ),
          ),
        ),
        Text(
          '${(goal.progress * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getGoalIcon(String iconName) {
    switch (iconName) {
      case 'house':
        return Icons.house;
      case 'car':
        return Icons.directions_car;
      case 'vacation':
        return Icons.beach_access;
      case 'education':
        return Icons.school;
      case 'emergency':
        return Icons.medical_services;
      default:
        return Icons.flag;
    }
  }

  // 🔥 THÊM DIALOG GÓP TIỀN
  void _showAddContributionDialog(SavingsGoal goal) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.attach_money, color: Color(0xFF009E60)),
            SizedBox(width: 8),
            Text('Góp tiền vào mục tiêu'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                goal.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF009E60),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hiện tại: ${intl.NumberFormat.decimalPattern('vi_VN').format(goal.currentAmount)}đ / ${intl.NumberFormat.decimalPattern('vi_VN').format(goal.targetAmount)}đ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền góp',
                  suffixText: 'đ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.green[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sau khi góp: ${intl.NumberFormat.decimalPattern('vi_VN').format(goal.currentAmount + (double.tryParse(amountController.text) ?? 0))}đ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập số tiền hợp lệ'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (amount > goal.remainingAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Số tiền vượt quá mục tiêu. Còn thiếu: ${intl.NumberFormat.decimalPattern('vi_VN').format(goal.remainingAmount)}đ'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                await _firebase.addToSavingsGoal(goal.id, amount);

                // Tạo transaction record nếu cần
                await _firebase.addTransaction({
                  'amount': amount,
                  'type': 'savings',
                  'category': 'Tiết kiệm',
                  'description': noteController.text.isNotEmpty
                      ? 'Góp tiền vào ${goal.name}: ${noteController.text}'
                      : 'Góp tiền vào ${goal.name}',
                  'date': DateTime.now(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '✅ Đã góp ${intl.NumberFormat.decimalPattern('vi_VN').format(amount)}đ vào ${goal.name}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009E60),
            ),
            child: const Text('Xác nhận góp tiền',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController targetController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Tạo mục tiêu mới'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên mục tiêu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền mục tiêu',
                      suffixText: 'đ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Ngày hoàn thành'),
                    subtitle: Text(
                        intl.DateFormat('dd/MM/yyyy').format(selectedDate)),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  final targetAmount = double.tryParse(targetController.text);
                  if (nameController.text.isNotEmpty &&
                      targetAmount != null &&
                      targetAmount > 0) {
                    _createNewGoal(
                      nameController.text,
                      targetAmount,
                      selectedDate,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Tạo mục tiêu'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _createNewGoal(String name, double targetAmount, DateTime targetDate) {
    final user = _firebase.currentUser;
    if (user != null) {
      final goal = SavingsGoal(
        id: _uuid.v4(),
        name: name,
        icon: 'flag',
        targetAmount: targetAmount,
        currentAmount: 0,
        targetDate: targetDate,
        category: 'Tiết kiệm',
        color: Colors.blue,
        createdAt: DateTime.now(),
      );
      _firebase.createSavingsGoal(goal);
    }
  }
}
