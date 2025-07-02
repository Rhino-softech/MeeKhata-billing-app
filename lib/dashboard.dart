import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_student_page.dart';
import 'course_page.dart';

class DashboardPage extends StatefulWidget {
  final String? userName;
  final String? email;

  const DashboardPage({super.key, this.userName, this.email});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedTabIndex = 0;
  List<Map<String, dynamic>> allTransactions = [];

  double todayPayment = 0;
  double totalDue = 0;
  int completedCount = 0;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  void fetchTransactions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    double todayPay = 0;
    double due = 0;
    int completed = 0;

    FirebaseFirestore.instance
        .collection('student_enroll_details')
        .snapshots()
        .listen((snapshot) {
          final List<Map<String, dynamic>> txList = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();

            final String name = data['name'] ?? 'Unknown';
            final String course = data['course_name'] ?? '';
            final double total = (data['total_fees'] ?? 0).toDouble();
            final double paid = (data['amount_paid'] ?? 0).toDouble();
            final Timestamp? paymentDate = data['last_payment_date'];
            final Timestamp? enrollDate = data['enrollment_date'];

            final DateTime? paidAt = paymentDate?.toDate();
            final DateTime? enrolledAt = enrollDate?.toDate();

            bool paidToday =
                paidAt != null &&
                paidAt.isAfter(startOfDay) &&
                paidAt.isBefore(endOfDay);

            if (paidToday) todayPay += paid;
            if (paid >= total) completed++;
            if (paid < total) due += (total - paid);

            txList.add({
              'name': name,
              'course': course,
              'total': total,
              'paid': paid,
              'due': (total - paid),
              'paidToday': paidToday,
              'date': enrolledAt,
            });
          }

          setState(() {
            allTransactions = txList;
            todayPayment = todayPay;
            totalDue = due;
            completedCount = completed;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredTransactions = [];

    switch (selectedTabIndex) {
      case 0:
        filteredTransactions = allTransactions;
        break;
      case 1:
        filteredTransactions =
            allTransactions.where((t) => t['paidToday'] == true).toList();
        break;
      case 2:
        filteredTransactions =
            allTransactions.where((t) => t['due'] <= 0).toList();
        break;
      case 3:
        filteredTransactions =
            allTransactions.where((t) => t['due'] > 0).toList();
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Dashboard', style: TextStyle(color: Colors.black)),
        elevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStudentPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CoursesPage()),
            );
          }
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Invoices'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            _topCard(
              'Today\'s Payment',
              '₹${todayPayment.toStringAsFixed(0)}',
              Colors.green,
              Icons.trending_up,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _topCard(
                    'Total Due',
                    '₹${totalDue.toStringAsFixed(0)}',
                    Colors.red,
                    Icons.error,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _topCard(
                    'Completed',
                    '$completedCount',
                    Colors.blue,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add Course',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42A5F5),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddStudentPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text(
                      'Add Student',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB458F3),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _tabChip("All", 0, allTransactions.length),
                _tabChip(
                  "Today",
                  1,
                  allTransactions.where((t) => t['paidToday']).length,
                ),
                _tabChip(
                  "Completed",
                  2,
                  allTransactions.where((t) => t['due'] <= 0).length,
                ),
                _tabChip(
                  "Due",
                  3,
                  allTransactions.where((t) => t['due'] > 0).length,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Transactions",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            ...filteredTransactions.map((t) => _transactionCard(t)),
          ],
        ),
      ),
    );
  }

  Widget _topCard(String title, String value, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(icon, color: Colors.white),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int index, int count) {
    final isSelected = selectedTabIndex == index;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => selectedTabIndex = index),
      selectedColor: Colors.black,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }

  Widget _transactionCard(Map<String, dynamic> data) {
    bool isPaid = data['due'] <= 0;
    DateTime? date = data['date'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 244, 244),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 231, 226, 226).withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// First Row: Name + Today + Amount Paid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    data['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (data['paidToday'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                '₹${data['paid'].toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          /// Course name and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['course'] ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              if (date != null)
                Text(
                  DateFormat('yyyy-MM-dd').format(date),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
            ],
          ),

          const SizedBox(height: 6),

          /// Due badge
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isPaid ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPaid ? 'Paid' : 'Due',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),

          const SizedBox(height: 6),

          /// Total, Paid, Due row
          Row(
            children: [
              Text(
                'Total: ₹${data['total'].toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 10),
              Text(
                'Paid: ₹${data['paid'].toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 10),
              Text(
                'Due: ₹${data['due'].toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// Progress bar
          LinearProgressIndicator(
            value:
                data['total'] > 0
                    ? (data['paid'] / data['total']).clamp(0.0, 1.0)
                    : 0.0,
            backgroundColor: Colors.grey[200],
            color: isPaid ? Colors.green : Colors.orange,
            minHeight: 4,
          ),
        ],
      ),
    );
  }
}
