import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'dashboard.dart';
import 'course_page.dart';
import 'tutor_page.dart';
import 'settings_page.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  String selectedCourse = 'All Courses';
  List<String> courseOptions = ['All Courses'];
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCourses();

    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _loadCourses() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('course_details').get();

    final courseNames =
        snapshot.docs
            .map((doc) => doc.data()['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();

    setState(() {
      courseOptions = ['All Courses', ...courseNames];
    });
  }

  Future<Uint8List> generateInvoicePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Student Invoice', style: pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 16),
                pw.Text('Name: ${data['name']}'),
                pw.Text('Course: ${data['course']}'),
                pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
                pw.Text('Total Fees: Rs.${data['total']}'),
                pw.Text('Amount Paid: Rs.${data['paid']}'),
                pw.Text('Due Amount: Rs.${data['due']}'),
              ],
            ),
      ),
    );
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Invoices',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('student_enroll_details')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          final invoices =
              docs
                  .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final double total = (data['total_fees'] ?? 0).toDouble();
                    final double paid = (data['amount_paid'] ?? 0).toDouble();
                    final double due = total - paid;

                    return {
                      'name': data['name'] ?? 'Unknown',
                      'course': data['course_name'] ?? 'Unknown Course',
                      'total': total,
                      'paid': paid,
                      'due': due,
                      'transactions':
                          (data['payment_history'] as List?)?.length ?? 0,
                      'status': due <= 0 ? 'Completed' : 'Pending',
                    };
                  })
                  .where((invoice) {
                    final matchesCourse =
                        selectedCourse == 'All Courses' ||
                        invoice['course'] == selectedCourse;
                    final matchesSearch =
                        searchQuery.isEmpty ||
                        invoice['name'].toString().toLowerCase().contains(
                          searchQuery,
                        ) ||
                        invoice['course'].toString().toLowerCase().contains(
                          searchQuery,
                        );
                    return matchesCourse && matchesSearch;
                  })
                  .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by student or course name...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: selectedCourse,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items:
                      courseOptions.map((course) {
                        return DropdownMenuItem(
                          value: course,
                          child: Text(course),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCourse = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (invoices.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Text(
                      "No matching records found.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                ...invoices.map((invoice) => _buildInvoiceCard(invoice)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
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
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TutorPage()),
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
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> data) {
    final bool isCompleted = data['status'] == 'Completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['name'],
                style: const TextStyle(
                  fontSize: 16,
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
                  data['status'],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(data['course'], style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: Rs.${data['total']}'),
              Text('Due: Rs.${data['due']}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Paid: Rs.${data['paid']}'),
              Text('Transactions: ${data['transactions']}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final pdfData = await generateInvoicePdf(data);
                    // TODO: Save or share the PDF using another package (like path_provider)
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final pdfData = await generateInvoicePdf(data);
                    // TODO: Handle WhatsApp sharing with custom logic
                  },
                  icon: const Icon(Icons.chat, color: Colors.green),
                  label: const Text('WhatsApp'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
