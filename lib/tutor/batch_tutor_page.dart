import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance_marker_page.dart'; // 🔁 Make sure to import this

class BatchTutorPage extends StatelessWidget {
  final String courseId;
  final String
  courseName; // this matches 'course_name' in student_enroll_details

  const BatchTutorPage({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  // 🔁 Fetch student count from student_enroll_details based on courseName and batchName
  Future<int> _getStudentCount(String courseName, String batchName) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('student_enroll_details')
            .where('course_name', isEqualTo: courseName)
            .where('batch_name', isEqualTo: batchName)
            .get();

    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            const Text(
              'Choose a Batch',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.logout, color: Colors.black),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('course_details')
                .doc(courseId)
                .get(),
        builder: (context, courseSnapshot) {
          if (courseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!courseSnapshot.hasData || !courseSnapshot.data!.exists) {
            return const Center(child: Text('No course data found.'));
          }

          final data = courseSnapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> batches = data['batches'] ?? [];

          if (batches.isEmpty) {
            return const Center(child: Text('No batches available.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: batches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final batch = batches[index] as Map<String, dynamic>;
              final batchName = batch['name'] ?? 'Unnamed Batch';

              return FutureBuilder<int>(
                future: _getStudentCount(courseName, batchName),
                builder: (context, studentSnapshot) {
                  final studentCount = studentSnapshot.data ?? 0;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AttendanceMarkPage(
                                courseName: courseName,
                                batchName: batchName,
                              ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFE8EBFF),
                            child: Icon(Icons.layers, color: Color(0xFF5669FF)),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                batchName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$studentCount students',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
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
          );
        },
      ),
    );
  }
}
