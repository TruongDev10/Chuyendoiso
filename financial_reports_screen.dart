import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({Key? key}) : super(key: key);

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  final FirebaseService _firebase = FirebaseService();
  String _selectedPeriod = 'month';
  int _touchedIndex = -1;
  DateTime _selectedDate = DateTime.now();
  FinancialReport? _cachedReport;
  List<QueryDocumentSnapshot>? _cachedTransactions;

  // Màu sắc cho biểu đồ
  final List<Color> _chartColors = [
    const Color(0xFF009E60),
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFD166),
    const Color(0xFF6A0572),
    const Color(0xFF118AB2),
    const Color(0xFF06D6A0),
    const Color(0xFFEF476F),
  ];

  @override
  Widget build(BuildContext context) {
    final user = _firebase.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Báo cáo tài chính')),
        body: const Center(child: Text('Vui lòng đăng nhập lại.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo tài chính'),
        backgroundColor: const Color(0xFF009E60),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDatePicker,
            tooltip: 'Chọn thời gian',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedPeriod = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('Tuần này')),
              const PopupMenuItem(value: 'month', child: Text('Tháng này')),
              const PopupMenuItem(value: 'quarter', child: Text('Quý này')),
              const PopupMenuItem(value: 'year', child: Text('Năm nay')),
              const PopupMenuItem(value: 'custom', child: Text('Tùy chọn')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebase.streamUserTransactions(user.uid),
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
                  Text(
                    'Lỗi: ${snapshot.error}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final transactions = snapshot.data!.docs;

          // Cache dữ liệu để tránh rebuild không cần thiết
          if (_cachedTransactions != transactions) {
            _cachedTransactions = transactions;
            _cachedReport = _generateReport(transactions);
          }

          return _buildReportContent();
        },
      ),
    );
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildReportContent() {
    if (_cachedReport == null) return _buildEmptyState();

    final dateRange = _getDateRange();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPeriodHeader(dateRange),
          const SizedBox(height: 16),
          _buildSummaryCards(_cachedReport!),
          const SizedBox(height: 20),
          _buildSavingsProgress(_cachedReport!),
          const SizedBox(height: 20),
          _buildSpendingChart(_cachedReport!),
          const SizedBox(height: 20),
          _buildCategoryBreakdown(_cachedReport!),
          const SizedBox(height: 20),
          if (_cachedTransactions != null)
            _buildTopTransactions(_cachedTransactions!),
          const SizedBox(height: 20),
          _buildInsights(_cachedReport!),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader(String dateRange) {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          dateRange,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Chưa có dữ liệu',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thêm giao dịch để xem báo cáo',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(FinancialReport report) {
    final savings = report.totalIncome - report.totalExpense;
    final savingsRate =
        report.totalIncome > 0 ? (savings / report.totalIncome * 100) : 0;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Tổng thu',
            report.totalIncome,
            Colors.green,
            Icons.arrow_upward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            'Tổng chi',
            report.totalExpense,
            Colors.red,
            Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            'Tiết kiệm',
            savings,
            savings >= 0 ? Colors.blue : Colors.orange,
            savings >= 0 ? Icons.savings : Icons.warning,
            subtitle: '${savingsRate.toStringAsFixed(1)}% thu nhập',
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, double amount, Color color, IconData icon,
      {String? subtitle}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${intl.NumberFormat.decimalPattern('vi_VN').format(amount)}đ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsProgress(FinancialReport report) {
    final savings = report.totalIncome - report.totalExpense;
    final isPositive = savings >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tình hình tiết kiệm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: report.totalIncome > 0
                  ? (savings / report.totalIncome).clamp(0.0, 1.0)
                  : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isPositive ? const Color(0xFF009E60) : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isPositive ? '✅ Đang tiết kiệm' : '⚠️ Đang chi tiêu vượt mức',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isPositive ? const Color(0xFF009E60) : Colors.orange,
                  ),
                ),
                Text(
                  '${intl.NumberFormat.decimalPattern('vi_VN').format(savings)}đ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? const Color(0xFF009E60) : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingChart(FinancialReport report) {
    if (report.categorySpending.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Chưa có dữ liệu chi tiêu',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, color: Color(0xFF009E60)),
                SizedBox(width: 8),
                Text(
                  'Phân bổ chi tiêu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Chỉ setState khi thực sự cần
                      final newIndex = pieTouchResponse
                              ?.touchedSection?.touchedSectionIndex ??
                          -1;
                      if (_touchedIndex != newIndex) {
                        setState(() {
                          _touchedIndex = newIndex;
                        });
                      }
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: _buildChartSections(report),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildChartLegend(report),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(FinancialReport report) {
    double totalSpending = report.categorySpending.values.fold(
      0,
      (previousValue, element) => previousValue + element,
    );

    return report.categorySpending.entries.map((entry) {
      final int index =
          report.categorySpending.keys.toList().indexOf(entry.key);
      final double percentage =
          totalSpending > 0 ? (entry.value / totalSpending) * 100 : 0;
      final bool isTouched = index == _touchedIndex;
      final double radius = isTouched ? 45 : 40;

      return PieChartSectionData(
        color: _chartColors[index % _chartColors.length],
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildChartLegend(FinancialReport report) {
    double totalSpending =
        report.categorySpending.values.fold(0, (sum, element) => sum + element);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: report.categorySpending.entries.map((entry) {
        final int index =
            report.categorySpending.keys.toList().indexOf(entry.key);
        final double percentage =
            totalSpending > 0 ? (entry.value / totalSpending) * 100 : 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _chartColors[index % _chartColors.length].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: _chartColors[index % _chartColors.length]),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _chartColors[index % _chartColors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                entry.key,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 4),
              Text(
                '${intl.NumberFormat.decimalPattern('vi_VN').format(entry.value)}đ',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryBreakdown(FinancialReport report) {
    final sortedCategories = report.categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category, color: Color(0xFF009E60)),
                SizedBox(width: 8),
                Text(
                  'Chi tiết theo danh mục',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedCategories
                .map((entry) => _buildCategoryItem(entry.key, entry.value))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: amount / (amount + 10000), // Giá trị tương đối
              backgroundColor: Colors.grey[200],
              valueColor:
                  AlwaysStoppedAnimation<Color>(const Color(0xFF009E60)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              '${intl.NumberFormat.decimalPattern('vi_VN').format(amount)}đ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTransactions(List<QueryDocumentSnapshot> transactions) {
    // Lấy 5 giao dịch lớn nhất
    final topTransactions = transactions.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['type'] == 'expense';
    }).toList();
    topTransactions.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      return (dataB['amount'] as num).compareTo(dataA['amount'] as num);
    });
    topTransactions.take(5).toList();

    if (topTransactions.isEmpty) {
      return const SizedBox();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list_alt, color: Color(0xFF009E60)),
                SizedBox(width: 8),
                Text(
                  'Giao dịch lớn nhất',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topTransactions.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _buildTransactionItem(data);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> data) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF009E60).withOpacity(0.1),
        child: const Icon(Icons.receipt, size: 20, color: Color(0xFF009E60)),
      ),
      title: Text(
        data['title'] ?? 'Không có tiêu đề',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        data['category'] ?? 'Khác',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Text(
        '-${intl.NumberFormat.decimalPattern('vi_VN').format(data['amount'])}đ',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.red,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildInsights(FinancialReport report) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Color(0xFF009E60)),
                SizedBox(width: 8),
                Text(
                  'Phân tích & Đề xuất',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...report.alerts
                .map(
                  (alert) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: alert.type == 'warning'
                          ? Colors.orange.withOpacity(0.1)
                          : alert.type == 'success'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: alert.type == 'warning'
                            ? Colors.orange
                            : alert.type == 'success'
                                ? Colors.green
                                : Colors.blue,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          alert.type == 'warning'
                              ? Icons.warning
                              : alert.type == 'success'
                                  ? Icons.check_circle
                                  : Icons.info,
                          color: alert.type == 'warning'
                              ? Colors.orange
                              : alert.type == 'success'
                                  ? Colors.green
                                  : Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            alert.message,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  FinancialReport _generateReport(List<QueryDocumentSnapshot> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categorySpending = {};

    for (var doc in transactions) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num).toDouble();
      final type = data['type'] as String;
      final category = data['category'] as String? ?? 'Khác';

      if (type == 'income') {
        totalIncome += amount;
      } else {
        totalExpense += amount;
        categorySpending[category] = (categorySpending[category] ?? 0) + amount;
      }
    }

    // Tạo alerts/thông báo thông minh
    List<SpendingAlert> alerts = [];

    final savings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? (savings / totalIncome * 100) : 0;

    if (savings < 0) {
      alerts.add(
        SpendingAlert(
          type: 'warning',
          message:
              '⚠️ Chi tiêu vượt quá thu nhập ${intl.NumberFormat.decimalPattern('vi_VN').format(-savings)}đ. Cần xem xét lại ngân sách.',
        ),
      );
    } else if (savingsRate >= 20) {
      alerts.add(
        SpendingAlert(
          type: 'success',
          message:
              '🎉 Xuất sắc! Bạn đang tiết kiệm được ${savingsRate.toStringAsFixed(1)}% thu nhập.',
        ),
      );
    } else if (savingsRate > 0) {
      alerts.add(
        SpendingAlert(
          type: 'info',
          message:
              '💡 Bạn đang tiết kiệm được ${savingsRate.toStringAsFixed(1)}% thu nhập. Mục tiêu lý tưởng là 20%.',
        ),
      );
    }

    final topCategory = _getTopSpendingCategory(categorySpending);
    if (topCategory != null) {
      final topAmount = categorySpending[topCategory]!;
      if (topAmount > totalIncome * 0.3) {
        // Chiếm hơn 30% thu nhập
        alerts.add(
          SpendingAlert(
            type: 'warning',
            message:
                '📊 "$topCategory" đang chiếm ${(topAmount / totalIncome * 100).toStringAsFixed(1)}% thu nhập. Xem xét tối ưu hóa.',
          ),
        );
      }
    }

    if (categorySpending.length <= 2) {
      alerts.add(
        SpendingAlert(
          type: 'info',
          message:
              '💼 Đa dạng hóa chi tiêu có thể giúp quản lý tài chính tốt hơn.',
        ),
      );
    }

    return FinancialReport(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      categorySpending: categorySpending,
      alerts: alerts,
    );
  }

  String? _getTopSpendingCategory(Map<String, double> categorySpending) {
    if (categorySpending.isEmpty) return null;
    return categorySpending.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  String _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return 'Tuần ${intl.DateFormat('dd/MM').format(startOfWeek)} - ${intl.DateFormat('dd/MM/yyyy').format(now)}';
      case 'month':
        return 'Tháng ${now.month}/${now.year}';
      case 'quarter':
        final quarter = ((now.month - 1) / 3).floor() + 1;
        return 'Quý $quarter/${now.year}';
      case 'year':
        return 'Năm ${now.year}';
      case 'custom':
        return 'Tùy chọn ${intl.DateFormat('dd/MM/yyyy').format(_selectedDate)}';
      default:
        return 'Tháng ${now.month}/${now.year}';
    }
  }
}

class FinancialReport {
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> categorySpending;
  final List<SpendingAlert> alerts;

  FinancialReport({
    required this.totalIncome,
    required this.totalExpense,
    required this.categorySpending,
    required this.alerts,
  });
}

class SpendingAlert {
  final String type; // 'warning', 'info', 'success'
  final String message;

  SpendingAlert({required this.type, required this.message});
}
