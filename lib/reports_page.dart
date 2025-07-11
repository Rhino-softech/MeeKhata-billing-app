import 'package:billing_app/settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'course_page.dart';
import 'invoice_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String searchQuery = '';
  String filterType = 'All'; // Options: All, Due, Completed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: const [Icon(Icons.refresh)],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('student_enroll_details')
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final students =
              docs
                  .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final total = (data['total_fees'] ?? 0).toDouble();
                    final paid = (data['amount_paid'] ?? 0).toDouble();
                    final due = total - paid;
                    final name = data['name'] ?? 'Unnamed';
                    final course = data['course_name'] ?? 'Unknown Course';
                    final status = due <= 0 ? 'Completed' : 'Due';

                    return {
                      'name': name,
                      'course': course,
                      'paid': paid,
                      'due': due,
                      'status': status,
                    };
                  })
                  .where((entry) {
                    final matchesSearch =
                        entry['name'].toString().toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        entry['course'].toString().toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        );
                    final matchesFilter =
                        filterType == 'All' ||
                        entry['status'] ==
                            (filterType == 'Completed' ? 'Completed' : 'Due');
                    return matchesSearch && matchesFilter;
                  })
                  .toList();

          final totalCollected = students.fold<double>(
            0,
            (sum, s) => sum + (s['paid'] as double),
          );
          final totalDue = students.fold<double>(
            0,
            (sum, s) => sum + (s['due'] as double),
          );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search students or courses...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
                const SizedBox(height: 12),

                /// Filters
                Row(
                  children: [
                    _buildFilterButton('All'),
                    const SizedBox(width: 8),
                    _buildFilterButton('Due'),
                    const SizedBox(width: 8),
                    _buildFilterButton('Completed'),
                  ],
                ),
                const SizedBox(height: 16),

                /// Totals
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Collected',
                        totalCollected,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Pending',
                        totalDue,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                /// Student Cards
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final s = students[index];
                      return _buildStudentCard(s);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CoursesPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const InvoicesPage()),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          }
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterButton(String label) {
    final isSelected = filterType == label;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => filterType = label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.black : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label == 'Due' ? 'Due Payments' : label),
      ),
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> s) {
    final isCompleted = s['status'] == 'Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Name + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s['name'],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.black : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCompleted ? 'Paid' : 'Due',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(s['course'], style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            'Paid: ₹${s['paid'].toStringAsFixed(0)}     Due: ₹${s['due'].toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
