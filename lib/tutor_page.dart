import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'course_page.dart';
import 'invoice_page.dart';
import 'settings_page.dart';
import 'student_tutor_page.dart';
import 'add_tutor_dialog.dart'; // ✅ Import your AddTutorForm page

class TutorPage extends StatefulWidget {
  final String loggedInUid; // ✅ store UID
  const TutorPage({super.key, required this.loggedInUid});

  @override
  State<TutorPage> createState() => _TutorPageState();
}

class _TutorPageState extends State<TutorPage> {
  int _selectedIndex = 3; // Tutor page index

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(loggedInUid: widget.loggedInUid),
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CoursesPage(uid: widget.loggedInUid)),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InvoicesPage(loggedInUid: widget.loggedInUid),
        ),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TutorPage(loggedInUid: widget.loggedInUid),
        ),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SettingsPage(loggedInUid: widget.loggedInUid),
        ),
      );
    }
  }

  void _showAddTutorForm() {
    showDialog(
      context: context,
      builder: (context) {
        return AddTutorForm(
          loggedInUid: widget.loggedInUid, // ✅ pass the UID
          onClose: () {
            Navigator.pop(context); // Close the dialog
            setState(() {}); // Refresh TutorPage after adding
          },
        );
      },
    );
  }

  void _showEditTutorForm(String tutorId, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final emailController = TextEditingController(text: data['email'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Tutor"),
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
                await FirebaseFirestore.instance
                    .collection('tutors')
                    .doc(tutorId)
                    .update({
                      'name': nameController.text,
                      'email': emailController.text,
                    });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteTutor(String tutorId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Tutor"),
            content: const Text("Are you sure you want to delete this tutor?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('tutors')
                      .doc(tutorId)
                      .delete();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Delete"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tutors")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Tabs Tutors / Students
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF1F1F1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Tutors",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => StudentPage(
                                  loggedInUid: widget.loggedInUid,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Students",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ Add Tutor Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _showAddTutorForm,
              icon: const Icon(Icons.add),
              label: const Text("Add Tutor"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            ),
          ),

          // ✅ Tutor List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('tutors')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tutors = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: tutors.length,
                  itemBuilder: (context, index) {
                    final doc = tutors[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final courses = data['courses'] as List<dynamic>? ?? [];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ Tutor Header with Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(data['email'] ?? ''),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.group),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => StudentPage(
                                                  loggedInUid:
                                                      widget.loggedInUid,
                                                ),
                                          ),
                                        );
                                      },
                                      tooltip: 'View Students',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed:
                                          () =>
                                              _showEditTutorForm(doc.id, data),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteTutor(doc.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // ✅ Chips
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    "${data['students'] ?? 0} Students",
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Chip(label: Text("${courses.length} Courses")),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // ✅ Courses List
                            const Text(
                              "Courses:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...courses.map(
                              (c) => Text(
                                "• ${c['courseName']} (${(c['batches'] as List?)?.length ?? 0} batch)",
                              ),
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

      // ✅ Bottom Nav
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
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
}
