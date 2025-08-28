import 'package:billing_app/settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_course_modal.dart';
import 'dashboard.dart';
import 'invoice_page.dart';
import 'batches_page.dart';
import 'tutor_page.dart';

class CoursesPage extends StatefulWidget {
  final String uid;

  const CoursesPage({super.key, required this.uid});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  List<Map<String, dynamic>> courses = [];
  late String userUid;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    userUid =
        widget.uid.isNotEmpty
            ? widget.uid
            : FirebaseAuth.instance.currentUser?.uid ?? '';
    fetchCoursesData();
  }

  /// ✅ Safe number parser (fix for zero issue)
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> fetchCoursesData() async {
    setState(() => isLoading = true);

    try {
      // ✅ Fetch student enrollments created by the logged-in user
      final enrollSnap =
          await FirebaseFirestore.instance
              .collection('student_enroll_details')
              .where('created_by_uid', isEqualTo: userUid)
              .get();

      Map<String, Map<String, dynamic>> stats = {};

      // ✅ Collect enrollment data grouped by course_name
      for (var doc in enrollSnap.docs) {
        final data = doc.data();
        final courseName = data['course_name'] ?? 'Unknown';

        final totalFees = _toDouble(data['total_fees']);
        final amountPaid = _toDouble(data['amount_paid']);
        final batchName = data['batch_name'] ?? '';

        stats[courseName] ??= {
          'name': courseName,
          'totalFee': 0.0,
          'collected': 0.0,
          'students': 0,
          'batchesSet': <String>{}, // unique batches
        };

        stats[courseName]!['totalFee'] =
            (stats[courseName]!['totalFee'] ?? 0.0) + totalFees;
        stats[courseName]!['collected'] =
            (stats[courseName]!['collected'] ?? 0.0) + amountPaid;
        stats[courseName]!['students'] =
            (stats[courseName]!['students'] ?? 0) + 1;

        if (batchName.toString().isNotEmpty) {
          (stats[courseName]!['batchesSet'] as Set<String>).add(batchName);
        }
      }

      // ✅ Prepare final result list
      final result =
          stats.entries.map((entry) {
            final data = entry.value;
            final totalFee = data['totalFee'] ?? 0.0;
            final collected = data['collected'] ?? 0.0;
            final remaining = totalFee - collected;
            final batchesCount = (data['batchesSet'] as Set<String>).length;

            return {
              'id': entry.key,
              'name': data['name'],
              'students': data['students'] ?? 0,
              'totalFee': totalFee,
              'collected': collected,
              'remaining': remaining,
              'batches': batchesCount,
            };
          }).toList();

      setState(() {
        courses = result;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching course data: $e");
      setState(() => isLoading = false);
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
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : courses.isEmpty
              ? const Center(
                child: Text(
                  "No courses found",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  final double percentage =
                      (course['totalFee'] ?? 0.0) == 0
                          ? 0.0
                          : (course['collected'] ?? 0.0) /
                              (course['totalFee'] ?? 1.0);

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
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                course['name'] ?? 'Unknown',
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

                        // Fee Info
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
                                        '₹${formatCurrency.format(course['totalFee'] ?? 0)}',
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
                                        '₹${formatCurrency.format(course['collected'] ?? 0)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                text: 'Remaining\n',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        '₹${formatCurrency.format(course['remaining'] ?? 0)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Progress bar
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

                        // View Batches
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
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardPage(loggedInUid: userUid),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => CoursesPage(uid: userUid)),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => InvoicesPage(loggedInUid: userUid),
              ),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TutorPage(loggedInUid: userUid),
              ),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(loggedInUid: userUid),
              ),
            );
          }
        },
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
