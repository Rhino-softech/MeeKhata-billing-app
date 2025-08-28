import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentPage extends StatefulWidget {
  final String loggedInUid;
  const StudentPage({super.key, required this.loggedInUid});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  bool showAssigned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Students"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Assigned/Unassigned toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildStatusToggle("Unassigned", !showAssigned),
                  _buildStatusToggle("Assigned", showAssigned),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('student_enroll_details')
                      .where('assigned', isEqualTo: showAssigned)
                      .orderBy('name')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No students found."));
                }

                final students = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final studentDoc = students[index];
                    final data = studentDoc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Student Details
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (data['email'] != null)
                                        Text(data['email']),
                                      if (data['phone'] != null)
                                        Text(data['phone']),
                                    ],
                                  ),
                                ),
                                if (data['course_name'] != null)
                                  Chip(
                                    label: Text(data['course_name']),
                                    backgroundColor: Colors.green[100],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Buttons
                            Row(
                              children: [
                                // ✅ Show "Assign" button only if student is NOT assigned
                                if (!showAssigned)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _showTutorAssignDialog(
                                        context,
                                        studentDoc.id,
                                        data,
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text("Assign"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                if (!showAssigned) const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => StudentDetailPage(
                                              studentId: studentDoc.id,
                                              studentData: data,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.remove_red_eye),
                                  label: const Text("View"),
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
    );
  }

  // ✅ Dialog to select tutor
  void _showTutorAssignDialog(
    BuildContext context,
    String studentId,
    Map<String, dynamic> studentData,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Assign Tutor"),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('tutors')
                      // ✅ FIX: Match student's course_id with tutor.assigned_course_ids
                      .where(
                        'assigned_course_ids',
                        arrayContains: studentData['course_id'],
                      )
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No tutors found for this course.");
                }

                final tutors = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: tutors.length,
                  itemBuilder: (context, index) {
                    final tutorDoc = tutors[index];
                    final tutorData = tutorDoc.data() as Map<String, dynamic>;

                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(tutorData['name'] ?? "No name"),
                      subtitle: Text(
                        "Email: ${tutorData['email'] ?? ''}\n"
                        "Institute: ${tutorData['institute']?['name'] ?? 'Unknown'}",
                      ),
                      onTap: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('student_enroll_details')
                              .doc(studentId)
                              .update({
                                'assigned': true,
                                'tutorId': tutorDoc.id,
                                // optional: store course for clarity
                                'course_id': studentData['course_id'],
                              });
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Assigned to ${tutorData['name']}",
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to assign: $e")),
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  // Toggle UI Widget
  Widget _buildStatusToggle(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!mounted) return;
          setState(() {
            showAssigned = label == "Assigned";
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected ? Colors.black : Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ New Page for Student Details
class StudentDetailPage extends StatelessWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const StudentDetailPage({
    super.key,
    required this.studentId,
    required this.studentData,
  });

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Unknown";
    try {
      if (timestamp is Timestamp) {
        return DateFormat('dd-MM-yyyy').format(timestamp.toDate());
      } else if (timestamp is DateTime) {
        return DateFormat('dd-MM-yyyy').format(timestamp);
      } else {
        return timestamp.toString();
      }
    } catch (_) {
      return "Invalid date";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              studentData['name'] ?? 'Unnamed',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (studentData['email'] != null)
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(studentData['email']),
              ),
            if (studentData['phone'] != null)
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(studentData['phone']),
              ),
            if (studentData['course_name'] != null)
              ListTile(
                leading: const Icon(Icons.book),
                title: Text("Course: ${studentData['course_name']}"),
              ),
            if (studentData['batch_name'] != null)
              ListTile(
                leading: const Icon(Icons.group),
                title: Text("Batch: ${studentData['batch_name']}"),
              ),
            if (studentData['amount_paid'] != null)
              ListTile(
                leading: const Icon(Icons.payments),
                title: Text("Amount Paid: ₹${studentData['amount_paid']}"),
              ),
            if (studentData['total_fees'] != null)
              ListTile(
                leading: const Icon(Icons.money),
                title: Text("Total Fees: ₹${studentData['total_fees']}"),
              ),
            if (studentData['enrollment_date'] != null)
              ListTile(
                leading: const Icon(Icons.date_range),
                title: Text(
                  "Enrollment Date: ${_formatDate(studentData['enrollment_date'])}",
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.assignment_ind),
              title: Text(
                "Assigned: ${studentData['assigned'] == true ? 'Yes' : 'No'}",
              ),
            ),
            // ✅ Tutor details if assigned
            if (studentData['tutorId'] != null)
              FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('tutors')
                        .doc(studentData['tutorId'])
                        .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const ListTile(
                      leading: Icon(Icons.person_off),
                      title: Text("Tutor not found"),
                    );
                  }
                  final tutorData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const Text(
                        "Assigned Tutor",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(tutorData['name'] ?? "No name"),
                        subtitle: Text(
                          "Email: ${tutorData['email'] ?? ''}\n"
                          "Institute: ${tutorData['institute']?['name'] ?? 'Unknown'}",
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('student_enroll_details')
                      .doc(studentId)
                      .delete();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Student deleted successfully"),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to delete student: $e")),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete),
              label: const Text("Delete Student"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
