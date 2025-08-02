import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:billing_app/tutor/batch_tutor_page.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  Future<DocumentSnapshot?> _getTutorDocByEmail(String email) async {
    // Step 1: Get user_details document based on email
    final userQuery =
        await FirebaseFirestore.instance
            .collection('user_details')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

    if (userQuery.docs.isEmpty) return null;

    final userData = userQuery.docs.first.data();
    final String userEmail = userData['email'];

    // Step 2: Now find matching tutor document by email
    final tutorQuery =
        await FirebaseFirestore.instance
            .collection('tutors')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();

    if (tutorQuery.docs.isEmpty) return null;

    return tutorQuery.docs.first;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("User not logged in."));
    }

    return FutureBuilder<DocumentSnapshot?>(
      future: _getTutorDocByEmail(currentUser.email!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("Tutor details not found."));
        }

        final tutorData = snapshot.data!.data() as Map<String, dynamic>;
        final String name = tutorData['name'] ?? 'Tutor';
        final List<dynamic> courses = tutorData['courses'] ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $name',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Your Courses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ Display tutor courses
              Expanded(
                child:
                    courses.isEmpty
                        ? const Center(child: Text("No courses assigned."))
                        : ListView.separated(
                          itemCount: courses.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final course = courses[index] ?? {};
                            final courseName =
                                course['name'] ?? 'Unnamed Course';
                            final courseId = course['id'] ?? 'unknown_id';

                            final List<dynamic> batches =
                                course['batches'] ?? [];
                            final int batchCount = batches.length;

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
