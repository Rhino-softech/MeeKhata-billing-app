import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_student_page.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  String _searchQuery = '';
  String _selectedStatus = 'All Status';

  String getStatus(double total, double paid, DateTime dueDate) {
    if (paid >= total) return 'Paid';
    if (DateTime.now().isAfter(dueDate)) return 'Overdue';
    return 'Pending';
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Overdue':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Student Management',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student List',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 5),
            const Text(
              'Search and filter students by name, course, or payment status',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Search bar and filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name, course, or phone...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items:
                      ['All Status', 'Paid', 'Pending', 'Overdue']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Student list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('student_enroll_details')
                        .orderBy('created_at', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  final filteredDocs =
                      docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name =
                            (data['name'] ?? '').toString().toLowerCase();
                        final course =
                            (data['course'] ?? '').toString().toLowerCase();
                        final phone =
                            (data['phone'] ?? '').toString().toLowerCase();
                        final total = (data['total_fees'] ?? 0).toDouble();
                        final paid = (data['amount_paid'] ?? 0).toDouble();
                        final dueDate =
                            (data['payment_due_date'] as Timestamp?)
                                ?.toDate() ??
                            DateTime.now();
                        final status = getStatus(total, paid, dueDate);

                        final matchesSearch =
                            name.contains(_searchQuery) ||
                            course.contains(_searchQuery) ||
                            phone.contains(_searchQuery);

                        final matchesStatus =
                            _selectedStatus == 'All Status' ||
                            status == _selectedStatus;

                        return matchesSearch && matchesStatus;
                      }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(child: Text('No students found'));
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data =
                          filteredDocs[index].data() as Map<String, dynamic>;
                      final name = data['name'] ?? '';
                      final course = data['course'] ?? '';
                      final phone = data['phone'] ?? '';
                      final email = data['email'] ?? '';
                      final total = (data['total_fees'] ?? 0).toDouble();
                      final paid = (data['amount_paid'] ?? 0).toDouble();
                      final dueDate =
                          (data['payment_due_date'] as Timestamp?)?.toDate();
                      final status = getStatus(
                        total,
                        paid,
                        dueDate ?? DateTime.now(),
                      );
                      final remaining = total - paid;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(
                                        status,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: getStatusColor(status),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('🔔 Reminders On'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Course: $course'),
                              Text('Phone: $phone'),
                              Text('Email: $email'),
                              if (dueDate != null)
                                Text(
                                  'Due Date: ${DateFormat('dd/MM/yyyy').format(dueDate)}',
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'Total: \$${total.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Paid: \$${paid.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Remaining: \$${remaining.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStudentPage()),
          );
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}
