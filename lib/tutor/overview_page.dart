import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  Future<Map<String, Map<String, dynamic>>> fetchBatches() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('student_enroll_details')
            .get();

    final Map<String, Map<String, dynamic>> batchData = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final courseName = data['course_name'];
      final batchName = data['batch_name'];
      final fullBatchName = "$batchName - $courseName";

      if (!batchData.containsKey(fullBatchName)) {
        batchData[fullBatchName] = {
          'name': fullBatchName,
          'students': 1,
          'schedule':
              'Schedule TBD', // You can update this with actual schedule data if available
        };
      } else {
        batchData[fullBatchName]!['students'] += 1;
      }
    }

    return batchData;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: fetchBatches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No batch data available."));
        }

        final batches = snapshot.data!.values.toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back, John Tutor',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              const Text(
                'My Batches',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...batches.map((batch) => _buildBatchCard(batch)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> batch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            batch['name'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      "${batch['students']} enrolled",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    batch['schedule'],
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Add navigation to detailed batch page
            },
            icon: const Icon(Icons.remove_red_eye),
            label: const Text("View Details"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
