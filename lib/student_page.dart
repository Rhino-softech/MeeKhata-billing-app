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

  void _showEditBottomSheet(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name']);
    final phoneController = TextEditingController(text: data['phone']);
    final emailController = TextEditingController(text: data['email']);
    final courseController = TextEditingController(text: data['course']);
    final totalFeesController = TextEditingController(
      text: data['total_fees'].toString(),
    );
    final amountPaidController = TextEditingController(
      text: data['amount_paid'].toString(),
    );

    DateTime? enrollmentDate = (data['created_at'] as Timestamp?)?.toDate();
    DateTime? dueDate = (data['payment_due_date'] as Timestamp?)?.toDate();

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    'Update student information and payment details.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Student Name *',
                    ),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                    ),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: courseController,
                    decoration: const InputDecoration(labelText: 'Course *'),
                  ),
                  TextField(
                    controller: totalFeesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Fees *',
                    ),
                  ),
                  TextField(
                    controller: amountPaidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount Paid'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text("Enrollment Date: "),
                      TextButton(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: enrollmentDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null) {
                            setState(() {
                              enrollmentDate = selected;
                            });
                          }
                        },
                        child: Text(
                          enrollmentDate != null
                              ? DateFormat('dd/MM/yyyy').format(enrollmentDate!)
                              : 'Select',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("Payment Due Date: "),
                      TextButton(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null) {
                            setState(() {
                              dueDate = selected;
                            });
                          }
                        },
                        child: Text(
                          dueDate != null
                              ? DateFormat('dd/MM/yyyy').format(dueDate!)
                              : 'Select',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('student_enroll_details')
                          .doc(doc.id)
                          .update({
                            'name': nameController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'email': emailController.text.trim(),
                            'course': courseController.text.trim(),
                            'total_fees':
                                double.tryParse(totalFeesController.text) ?? 0,
                            'amount_paid':
                                double.tryParse(amountPaidController.text) ?? 0,
                            'created_at': enrollmentDate ?? DateTime.now(),
                            'payment_due_date': dueDate ?? DateTime.now(),
                          });
                      Navigator.pop(context);
                    },
                    child: const Text('Update Student'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
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
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
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
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showEditBottomSheet(doc),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
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
