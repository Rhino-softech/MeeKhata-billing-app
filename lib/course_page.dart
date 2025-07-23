import 'package:billing_app/settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_course_modal.dart';
import 'dashboard.dart';
import 'student_details_page.dart';
import 'invoice_page.dart';
import 'batches_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';

class CoursesPage extends StatefulWidget {
  final String? userName;
  final String? email;

  const CoursesPage({super.key, this.userName, this.email});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  List<Map<String, dynamic>> courses = [];
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    fetchCoursesData();
  }

  Future<void> fetchCoursesData() async {
    final courseSnap =
        await FirebaseFirestore.instance.collection('course_details').get();

    final enrollSnap =
        await FirebaseFirestore.instance
            .collection('student_enroll_details')
            .get();

    Map<String, Map<String, dynamic>> stats = {};

    for (var doc in enrollSnap.docs) {
      final data = doc.data();
      final courseName = data['course_name'];
      final totalFees = (data['total_fees'] ?? 0).toDouble();
      final amountPaid = (data['amount_paid'] ?? 0).toDouble();

      if (courseName == null) continue;

      stats[courseName] ??= {
        'totalFee': 0.0,
        'collected': 0.0,
        'students': 0,
        'batches': 0,
      };

      stats[courseName]!['totalFee'] += totalFees;
      stats[courseName]!['collected'] += amountPaid;
      stats[courseName]!['students'] += 1;
    }

    for (var doc in courseSnap.docs) {
      final data = doc.data();
      final name = data['name'] ?? 'Unknown';
      final count = data['count'] ?? 0;

      stats[name] ??= {'totalFee': 0.0, 'collected': 0.0, 'students': 0};

      stats[name]!['batches'] = count;
    }

    final result =
        stats.entries.map((entry) {
          final name = entry.key;
          final data = entry.value;
          return {
            'name': name,
            'students': data['students'],
            'totalFee': data['totalFee'],
            'collected': data['collected'],
            'batches': data['batches'],
          };
        }).toList();

    setState(() {
      courses = result;
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    Widget? targetPage;
    switch (index) {
      case 0:
        targetPage = DashboardPage(
          userName: widget.userName,
          email: widget.email,
        );
        break;
      case 1:
        return;
      case 2:
        targetPage = InvoicesPage();
        break;
      case 3:
        targetPage = TutorPage();
        break;
      case 4:
        targetPage = SettingsPage();
        break;
      default:
        return;
    }

    if (targetPage != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetPage!),
      );
    }
  }

  void _openAddCourseDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCourseModal(onSubmit: fetchCoursesData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.decimalPattern('en_IN');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Courses"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: fetchCoursesData,
            icon: const Icon(Icons.refresh),
          ),
        ],
        leading: IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
      ),
      body:
          courses.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  final double percentage =
                      course['totalFee'] == 0
                          ? 0.0
                          : course['collected'] / course['totalFee'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.05),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Title + Tags
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                course['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                _buildTag('${course['batches']} batches'),
                                const SizedBox(width: 6),
                                _buildTag('${course['students']} students'),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        /// Fees row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                text: 'Total Fee\n',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        '₹${formatCurrency.format(course['totalFee'])}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                text: 'Collected\n',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        '₹${formatCurrency.format(course['collected'])}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        /// Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey[300],
                            color: Colors.green,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),

                        /// View Batches Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => BatchesPage(
                                        courseName: course['name'],
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.groups, size: 18),
                            label: Text(
                              'View Batches (${course['batches']})',
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddCourseDialog,
        backgroundColor: const Color(0xFFB458F3),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
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
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
