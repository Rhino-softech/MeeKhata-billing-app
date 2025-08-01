import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddCourseModal extends StatefulWidget {
  final VoidCallback onSubmit;

  const AddCourseModal({super.key, required this.onSubmit});

  @override
  State<AddCourseModal> createState() => _AddCourseModalState();
}

class _AddCourseModalState extends State<AddCourseModal> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String description = '';
  String fee = '';
  String duration = '';
  String courseType = 'normal'; // default type
  List<Map<String, String>> batches = [];

  bool _isSubmitting = false;

  void _addBatchDialog() {
    String batchName = '';
    String classTime = '';
    String tutorName = '';

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Batches',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add batches with class schedules and tutors',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add New Batch',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Batch Name *',
                            hintText: 'e.g., Morning Batch, Weekend Batch',
                          ),
                          onChanged: (value) => batchName = value,
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Class Time *',
                            hintText: 'e.g., 9:00 AM - 11:00 AM',
                          ),
                          onChanged: (value) => classTime = value,
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Tutor Name *',
                            hintText: 'e.g., John Doe, Dr. Smith',
                          ),
                          onChanged: (value) => tutorName = value,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (batchName.isNotEmpty &&
                                  classTime.isNotEmpty &&
                                  tutorName.isNotEmpty) {
                                setState(() {
                                  batches.add({
                                    'name': batchName,
                                    'time': classTime,
                                    'tutor': tutorName,
                                  });
                                });
                                Navigator.pop(context);
                              }
                            },
                            label: const Text('Add Batch'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF90B4F0),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Top Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add New Course',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Create a new course for student enrollment',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    label: 'Course Name *',
                    hint: 'e.g., Advanced JavaScript',
                    onChanged: (val) => name = val,
                    validator:
                        (val) =>
                            val!.isEmpty ? 'Course name is required' : null,
                  ),
                  _buildTextField(
                    label: 'Description',
                    hint: 'Brief course description',
                    onChanged: (val) => description = val,
                  ),
                  _buildTextField(
                    label: 'Course Fee *',
                    hint: 'Enter course fee',
                    keyboardType: TextInputType.number,
                    onChanged: (val) => fee = val,
                    validator: (val) => val!.isEmpty ? 'Fee is required' : null,
                  ),
                  _buildTextField(
                    label: 'Duration',
                    hint: 'e.g., 3 months, 6 weeks',
                    onChanged: (val) => duration = val,
                  ),
                  const SizedBox(height: 10),

                  /// Course Type Dropdown
                  DropdownButtonFormField<String>(
                    value: courseType,
                    items: const [
                      DropdownMenuItem(
                        value: 'normal',
                        child: Text('Normal Course'),
                      ),
                      DropdownMenuItem(
                        value: 'addon',
                        child: Text('Addon Course'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Course Type *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      if (val != null) setState(() => courseType = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  /// Batch Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Batches (${batches.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addBatchDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Batch'),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (batches.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          batches
                              .map(
                                (batch) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, size: 6),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${batch['name']} - ${batch['time']} - ${batch['tutor']}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.grey),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed:
                              _isSubmitting
                                  ? null
                                  : () async {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() => _isSubmitting = true);

                                      final currentUser =
                                          FirebaseAuth.instance.currentUser;
                                      final instituteId = currentUser?.uid;

                                      if (instituteId == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Unable to identify current institute.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final courseRef = await FirebaseFirestore
                                          .instance
                                          .collection('courses')
                                          .add({
                                            'name': name.trim(),
                                            'type': courseType,
                                            'institute_id': instituteId,
                                            'created_at': Timestamp.now(),
                                            'fee': double.tryParse(fee) ?? 0.0,
                                            'duration': duration.trim(),
                                          });

                                      for (final batch in batches) {
                                        await FirebaseFirestore.instance
                                            .collection('batches')
                                            .add({
                                              'course_id': courseRef.id,
                                              'institute_id': instituteId,
                                              'name': batch['name'],
                                              'time': batch['time'],
                                              'tutor': batch['tutor'],
                                              'created_at': Timestamp.now(),
                                            });
                                      }

                                      setState(() => _isSubmitting = false);
                                      Navigator.of(context).pop();
                                      widget.onSubmit();
                                    }
                                  },
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text('+ Add Course'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    required void Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 6),
          TextFormField(
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: keyboardType,
            validator: validator,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
