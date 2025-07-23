import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'course_page.dart';
import 'invoice_page.dart';
import 'settings_page.dart';

class TutorPage extends StatefulWidget {
  const TutorPage({super.key});

  @override
  State<TutorPage> createState() => _TutorPageState();
}

class _TutorPageState extends State<TutorPage> {
  bool showTutors = true;

  void _showAddTutorDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Add Tutor"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();

                  if (name.isNotEmpty && email.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('tutors').add({
                      'name': name,
                      'email': email,
                      'courses': [],
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }

  Widget _buildTutorCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final courses = data['courses'] as List<dynamic>? ?? [];

    int totalStudents = 0;
    for (var c in courses) {
      totalStudents += ((c['student_count'] ?? 0) as num).toInt();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.group),
                  tooltip: 'View Students',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Tutor',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete Tutor',
                  onPressed:
                      () =>
                          FirebaseFirestore.instance
                              .collection('tutors')
                              .doc(doc.id)
                              .delete(),
                ),
              ],
            ),
            Text(data['email'], style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text('$totalStudents Students')),
                const SizedBox(width: 8),
                Chip(label: Text('${courses.length} Courses')),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Courses:'),
            for (var course in courses)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  '• ${course['course_name']} (${course['batch_count']} batch)',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tutors').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tutors',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddTutorDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Tutor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...docs.map(_buildTutorCard).toList(),
          ],
        );
      },
    );
  }

  Widget _buildStudentsTabPlaceholder() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          "Student tab coming soon...",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tutors",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: const [Icon(Icons.refresh)],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          ToggleButtons(
            isSelected: [showTutors, !showTutors],
            onPressed: (index) => setState(() => showTutors = index == 0),
            borderRadius: BorderRadius.circular(12),
            selectedColor: Colors.white,
            fillColor: Colors.black,
            color: Colors.black,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.school),
                    SizedBox(width: 6),
                    Text("Tutors"),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 6),
                    Text("Students"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child:
                showTutors
                    ? _buildTutorsList()
                    : _buildStudentsTabPlaceholder(),
          ),
        ],
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
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Invoices'),
          BottomNavigationBarItem(
            icon: Icon(Icons.supervisor_account),
            label: 'Tutors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
