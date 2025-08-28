import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:billing_app/tutor/batch_tutor_page.dart';

class AttendancePage extends StatefulWidget {
  final String loggedInUid; // ✅ UID passed from login page (tutor docId)

  const AttendancePage({super.key, required this.loggedInUid});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  int _selectedIndex = 0;

  // 🔹 Stream tutor details in real-time
  Stream<Map<String, dynamic>?> _getTutorDetails(String tutorId) {
    return FirebaseFirestore.instance
        .collection('tutors')
        .doc(tutorId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  // 🔹 Stream tutor courses in real-time
  Stream<List<Map<String, dynamic>>> _getTutorCourses(String tutorId) {
    return FirebaseFirestore.instance
        .collection('student_enroll_details')
        .where('tutorId', isEqualTo: tutorId)
        .snapshots()
        .asyncMap((query) async {
          Map<String, Map<String, dynamic>> courseStats = {};

          for (var doc in query.docs) {
            final data = doc.data();
            final String courseId = data['courseId'] ?? doc.id;

            // 🔹 First check if courseName exists in student_enroll_details
            String courseName = data['course_name'] ?? '';

            if (courseName.isEmpty) {
              // 🔹 If not, fetch from courses collection
              final courseDoc =
                  await FirebaseFirestore.instance
                      .collection('courses')
                      .doc(courseId)
                      .get();

              final courseData = courseDoc.data() ?? {};
              courseName = courseData['courseName'] ?? 'Unnamed Course';
            }

            // 🔹 Get batch_name (single value per enrollment)
            final String batchName = data['batch_name'] ?? '';

            // 🔹 Initialize course entry if not exists
            courseStats[courseId] ??= {
              'id': courseId,
              'name': courseName,
              'batchesSet': <String>{}, // store unique batch names
            };

            if (batchName.trim().isNotEmpty) {
              (courseStats[courseId]!['batchesSet'] as Set<String>).add(
                batchName,
              );
            }
          }

          // 🔹 Convert to list with batchCount
          return courseStats.values.map((course) {
            final batchSet = course['batchesSet'] as Set<String>;
            return {
              'id': course['id'],
              'name': course['name'],
              'batchCount': batchSet.length, // ✅ Final batch count
            };
          }).toList();
        });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // 🔹 You can handle page navigation here later if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _getTutorDetails(widget.loggedInUid),
      builder: (context, tutorSnapshot) {
        if (tutorSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!tutorSnapshot.hasData || tutorSnapshot.data == null) {
          return const Center(child: Text("Tutor details not found."));
        }

        final tutorData = tutorSnapshot.data!;
        final String name = tutorData['name'] ?? 'Tutor';

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blue,
            title: const Text(
              "Tutor Dashboard",
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _getTutorCourses(widget.loggedInUid),
            builder: (context, courseSnapshot) {
              if (courseSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!courseSnapshot.hasData || courseSnapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $name',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          "No courses assigned.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final courses = courseSnapshot.data!;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $name',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Your Courses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ✅ Display tutor courses in real-time
                    Expanded(
                      child: ListView.separated(
                        itemCount: courses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          final courseName = course['name'] ?? 'Unnamed Course';
                          final courseId = course['id'] ?? 'unknown_id';

                          final int batchCount = course['batchCount'] ?? 0;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => BatchTutorPage(
                                        courseId: courseId,
                                        courseName: courseName,
                                      ),
                                ),
                              );
                            },
                            child: _buildCourseCard(
                              courseName,
                              '$batchCount batches available',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // 🔹 Bottom Navigation Bar added
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.check_circle_outline),
                label: 'Attendance',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Students',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Overview',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.message),
                label: 'Messages',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCourseCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.menu_book, size: 24, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
