import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'course_page.dart';
// import 'reports_page.dart';
// import 'settings_page.dart';

class InvoicesPage extends StatelessWidget {
  final List<Map<String, dynamic>> invoices = [
    {
      'name': 'Arjun Sharma',
      'course': 'React Development',
      'total': 5000,
      'paid': 3000,
      'due': 2000,
      'transactions': 2,
      'status': 'Pending',
    },
    {
      'name': 'Priya Patel',
      'course': 'Python Programming',
      'total': 5000,
      'paid': 5000,
      'due': 0,
      'transactions': 2,
      'status': 'Completed',
    },
    {
      'name': 'Rahul Kumar',
      'course': 'Data Science',
      'total': 12000,
      'paid': 8000,
      'due': 4000,
      'transactions': 2,
      'status': 'Pending',
    },
    {
      'name': 'Sneha Gupta',
      'course': 'UI/UX Design',
      'total': 5000,
      'paid': 2000,
      'due': 3000,
      'transactions': 2,
      'status': 'Pending',
    },
  ];

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
        actions: const [
          Icon(Icons.search, color: Colors.black),
          SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search students by name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.filter_alt_outlined),
                SizedBox(width: 10),
                Text('All Courses'),
                Spacer(),
                Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...invoices.map((invoice) => _buildInvoiceCard(invoice)).toList(),
        ],
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
            // } else if (index == 3) {
            //   Navigator.pushReplacement(
            //     context,
            //     MaterialPageRoute(builder: (_) => const ReportsPage()),
            //   );
            // } else if (index == 4) {
            //   Navigator.pushReplacement(
            //     context,
            //     MaterialPageRoute(builder: (_) => const SettingsPage()),
            //   );
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
          /// Name + Status
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

          /// Total, Paid, Due, Transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: ₹${data['total']}'),
              Text('Due: ₹${data['due']}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Paid: ₹${data['paid']}'),
              Text('Transactions: ${data['transactions']}'),
            ],
          ),
          const SizedBox(height: 12),

          /// Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
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
