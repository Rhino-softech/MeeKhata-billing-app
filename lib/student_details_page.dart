import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'update_payment_page.dart';

class StudentDetailsPage extends StatefulWidget {
  final String courseName;

  const StudentDetailsPage({super.key, required this.courseName});

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  void fetchStudents() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('student_enroll_details')
            .where('course_name', isEqualTo: widget.courseName)
            .get();

    final List<Map<String, dynamic>> loadedStudents = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      loadedStudents.add({
        'id': doc.id,
        'name': data['name'] ?? 'Unnamed',
        'phone': data['phone'] ?? '',
        'total_fee': (data['total_fees'] ?? 0).toDouble(),
        'amount_paid': (data['amount_paid'] ?? 0).toDouble(),
      });
    }

    setState(() {
      students = loadedStudents;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalStudents = students.length;
    double collected = students.fold(
      0.0,
      (sum, s) => sum + (s['amount_paid'] ?? 0.0),
    );
    double totalFee = students.fold(
      0.0,
      (sum, s) => sum + (s['total_fee'] ?? 0.0),
    );
    double pending = totalFee - collected;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(widget.courseName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(onPressed: fetchStudents, icon: const Icon(Icons.refresh)),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    /// Summary Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryTile(
                            Icons.person,
                            'Students',
                            totalStudents.toString(),
                          ),
                          _buildSummaryTile(
                            Icons.currency_rupee,
                            'Collected',
                            '₹${collected.toStringAsFixed(0)}',
                          ),
                          _buildSummaryTile(
                            Icons.timer_outlined,
                            'Pending',
                            '₹${pending.toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                    ),

                    /// Student Cards
                    for (var student in students) _buildStudentCard(student),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add student logic
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const SizedBox(height: 60),
    );
  }

  Widget _buildSummaryTile(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final double total = student['total_fee'];
    final double paid = student['amount_paid'];
    final double due = total - paid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        student['phone'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: paid >= total ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  paid >= total ? 'Paid' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    color: paid >= total ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          /// Fee details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Fee\n₹${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                'Paid\n₹${paid.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 13,
                ),
              ),
              Text(
                'Due\n₹${due.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          /// Update Payment Button -> Navigates
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => UpdatePaymentPage(
                          student: student,
                          courseName: widget.courseName,
                        ),
                  ),
                );
              },
              child: const Text('Update Payment'),
            ),
          ),
        ],
      ),
    );
  }
}
