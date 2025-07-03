import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BatchDialog extends StatefulWidget {
  final String courseId; // 🔹 Course document ID in 'course_details'
  final Function(Map<String, String>) onAdd;

  const BatchDialog({super.key, required this.onAdd, required this.courseId});

  @override
  State<BatchDialog> createState() => _BatchDialogState();
}

class _BatchDialogState extends State<BatchDialog> {
  final _formKey = GlobalKey<FormState>();
  String batchName = '';
  String classTime = '';
  String tutorName = '';

  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 500, // Increased width
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Manage Batches',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add batches with class schedules and tutors',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  /// Blue Box Panel
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add New Batch',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Batch Name *',
                          hint: 'e.g., Morning Batch, Weekend Batch',
                          onChanged: (val) => batchName = val,
                          validator:
                              (val) =>
                                  val!.isEmpty
                                      ? 'Batch name is required'
                                      : null,
                        ),
                        _buildTextField(
                          label: 'Class Time *',
                          hint: 'e.g., 9:00 AM - 11:00 AM',
                          onChanged: (val) => classTime = val,
                          validator:
                              (val) =>
                                  val!.isEmpty
                                      ? 'Class time is required'
                                      : null,
                        ),
                        _buildTextField(
                          label: 'Tutor Name *',
                          hint: 'e.g., John Doe, Dr. Smith',
                          onChanged: (val) => tutorName = val,
                          validator:
                              (val) =>
                                  val!.isEmpty
                                      ? 'Tutor name is required'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon:
                                _isSubmitting
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                    ),
                            label: Text(
                              _isSubmitting ? 'Adding...' : 'Add Batch',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7DA6F5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed:
                                _isSubmitting
                                    ? null
                                    : () async {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() => _isSubmitting = true);

                                        final batchData = {
                                          'name': batchName,
                                          'time': classTime,
                                          'tutor': tutorName,
                                          'created_at': Timestamp.now(),
                                        };

                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('course_details')
                                              .doc(widget.courseId)
                                              .collection(
                                                'batches',
                                              ) // 🔹 Subcollection
                                              .add(batchData);

                                          widget.onAdd(
                                            batchData.map(
                                              (key, value) => MapEntry(
                                                key,
                                                value.toString(),
                                              ),
                                            ),
                                          );
                                          Navigator.of(context).pop();
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to add batch: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(
                                              () => _isSubmitting = false,
                                            );
                                          }
                                        }
                                      }
                                    },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Done Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
    required void Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: validator,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
