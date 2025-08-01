import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'update_payment_page.dart'; // ✅ Import your page

class BatchStudentsPage extends StatelessWidget {
  final String courseName;
  final String batchName;
  final String batchTime;
  final String tutorName;

  const BatchStudentsPage({
    super.key,
    required this.courseName,
    required this.batchName,
    required this.batchTime,
    required this.tutorName,
  });

  Future<List<Map<String, dynamic>>> fetchStudents() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('student_enroll_details')
            .where('course_name', isEqualTo: courseName)
            .where('batch_name', isEqualTo: batchName)
            .get();

    return snap.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text('$batchName - Students'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data ?? [];
          double totalPaid = 0;
          double totalFee = 0;

          for (var s in students) {
            totalPaid += (s['amount_paid'] ?? 0).toDouble();
            totalFee += (s['total_fees'] ?? 0).toDouble();
          }

          final due = totalFee - totalPaid;
          final percentage = totalFee == 0 ? 0.0 : (totalPaid / totalFee);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              /// Header Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFB458F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batchName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Class Time\n$batchTime",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "Tutor\n$tutorName",
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${students.length} students enrolled",
                      style: const TextStyle(
                        color: Color(0xFFD0D9FF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// Profit and Due Cards
              Row(
                children: [
                  _buildInfoCard(
                    "Total Profit",
                    formatCurrency.format(totalPaid),
                    Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoCard(
                    "Total Due",
                    formatCurrency.format(due),
                    Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Collection Progress",
                    style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[300],
                      color: Colors.green,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${formatCurrency.format(totalPaid)} collected    ${formatCurrency.format(totalFee)} total",
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// Student Cards
              ...students.map((student) {
                final double paid = (student['amount_paid'] ?? 0).toDouble();
                final double total = (student['total_fees'] ?? 0).toDouble();
                final double due = total - paid;

                // ✅ Calculate attendance %
                final int totalClasses = student['total_classes'] ?? 0;
                final int attendedClasses = student['attended_classes'] ?? 0;
                final int attendancePercent =
                    totalClasses == 0
                        ? 0
                        : ((attendedClasses / totalClasses) * 100).round();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Top Row
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFE7E7E7),
                            child: Icon(Icons.person, color: Colors.black),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                student['phone'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Chip(
                            label: Text('Pending'),
                            labelStyle: TextStyle(fontSize: 11),
                            backgroundColor: Colors.redAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      /// Attendance % (Replaces Progress)
                      Row(
                        children: [
                          const Text(
                            "Attendance: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "$attendancePercent%",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      /// Payment Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMoneyText(
                            'Total Fee',
                            formatCurrency.format(total),
                          ),
                          _buildMoneyText(
                            'Paid',
                            formatCurrency.format(paid),
                            color: Colors.green,
                          ),
                          _buildMoneyText(
                            'Due',
                            formatCurrency.format(due),
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      /// Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => UpdatePaymentPage(
                                          student: student,
                                          courseName: courseName,
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                              ),
                              child: const Text("Update Payment"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              // Optional: Add extra actions
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Batches'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoneyText(
    String label,
    String value, {
    Color color = Colors.black,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
