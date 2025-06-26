import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_page.dart';

class DashboardPage extends StatelessWidget {
  final String? userName;
  final String? email;

  const DashboardPage({super.key, this.userName, this.email});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Billing System',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Welcome, ${userName ?? "User"}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_outline, color: Colors.black),
            label: const Text(
              'Employee',
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.black),
            label: const Text('Logout', style: TextStyle(color: Colors.black)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('student_enroll_details')
                .snapshots(),
        builder: (context, snapshot) {
          int total = 0;
          int paid = 0;
          int pending = 0;
          int overdue = 0;
          double totalAmount = 0;
          double dueAmount = 0;

          if (snapshot.hasData) {
            final now = DateTime.now();
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final double totalFees = (data['total_fees'] ?? 0).toDouble();
              final double amountPaid = (data['amount_paid'] ?? 0).toDouble();
              final Timestamp? dueTimestamp = data['payment_due_date'];
              final DateTime dueDate = dueTimestamp?.toDate() ?? now;

              total++;
              totalAmount += totalFees;
              dueAmount += (totalFees - amountPaid).clamp(0, totalFees);

              if (amountPaid >= totalFees) {
                paid++;
              } else if (dueDate.isBefore(now)) {
                overdue++;
              } else {
                pending++;
              }
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.shade300, blurRadius: 4),
                        ],
                      ),
                      child: const Text(
                        'Dashboard',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Students',
                        style: TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStatCard(
                        'Total Students',
                        '$total',
                        Icons.group_outlined,
                        Colors.black,
                      ),
                      _buildStatCard(
                        'Paid',
                        '$paid',
                        Icons.attach_money,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Pending',
                        '$pending',
                        Icons.access_time,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Overdue',
                        '$overdue',
                        Icons.error_outline,
                        Colors.red,
                      ),
                      _buildStatCard(
                        'Total Amount',
                        '₹${totalAmount.toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Due Amount',
                        '₹${dueAmount.toStringAsFixed(2)}',
                        Icons.money_off,
                        Colors.purple,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Students',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Latest student registrations and updates',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
