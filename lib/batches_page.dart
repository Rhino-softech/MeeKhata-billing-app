import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'batch_students_page.dart';

class BatchesPage extends StatefulWidget {
  final String courseName;

  const BatchesPage({super.key, required this.courseName});

  @override
  State<BatchesPage> createState() => _BatchesPageState();
}

class _BatchesPageState extends State<BatchesPage> {
  List<Map<String, dynamic>> batches = [];
  int totalStudents = 0;

  @override
  void initState() {
    super.initState();
    fetchBatches();
  }

  Future<void> fetchBatches() async {
    final query =
        await FirebaseFirestore.instance
            .collection('course_details')
            .where('name', isEqualTo: widget.courseName)
            .get();

    if (query.docs.isEmpty) return;

    final doc = query.docs.first;
    final batchList = List<Map<String, dynamic>>.from(doc['batches']);

    List<Map<String, dynamic>> enrichedBatches = [];

    for (var batch in batchList) {
      final batchName = batch['name'];
      final studentQuery =
          await FirebaseFirestore.instance
              .collection('student_enroll_details')
              .where('course_name', isEqualTo: widget.courseName)
              .where('batch_name', isEqualTo: batchName)
              .get();

      batch['studentCount'] = studentQuery.docs.length;
      enrichedBatches.add(batch);
    }

    setState(() {
      batches = enrichedBatches;
      totalStudents = enrichedBatches.fold(
        0,
        (sum, b) => sum + ((b['studentCount'] ?? 0) as int),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text('${widget.courseName} - Batches'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(onPressed: fetchBatches, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          /// Course Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2F60FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.courseName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${batches.length} batches • $totalStudents total students',
                        style: const TextStyle(
                          color: Color(0xFFD0D9FF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          /// Batch Cards
          ...batches.map(
            (batch) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildBatchCard(
                context,
                title: batch['name'] ?? '',
                time: batch['time'] ?? '',
                trainer: batch['tutor'] ?? '',
                studentCount: batch['studentCount'] ?? 0,
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// Back Button
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Courses'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black87,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchCard(
    BuildContext context, {
    required String title,
    required String time,
    required String trainer,
    required int studentCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Batch Title
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          /// Time
          Row(
            children: [
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 6),
              Text(time, style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),

          /// Tutor + Students Tag
          Row(
            children: [
              const Icon(Icons.person, size: 16),
              const SizedBox(width: 6),
              Text(trainer, style: const TextStyle(fontSize: 13)),
              const Spacer(),
              _buildStudentTag(studentCount),
            ],
          ),
          const SizedBox(height: 10),

          /// View Students Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => BatchStudentsPage(
                          courseName: widget.courseName,
                          batchName: title,
                          batchTime: time,
                          tutorName: trainer,
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.people_alt_outlined, size: 18),
              label: Text("View Students ($studentCount)"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTag(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count students',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
