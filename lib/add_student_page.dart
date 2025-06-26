import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _totalFeesController = TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();

  String? _selectedCourse;
  DateTime? _enrollmentDate;
  DateTime? _dueDate;

  final List<String> _courses = ['Flutter', 'React', 'Python', 'Java'];

  Future<void> _selectDate(BuildContext context, bool isEnrollment) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isEnrollment) {
          _enrollmentDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('student_enroll_details')
            .add({
              'name': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'email': _emailController.text.trim(),
              'course': _selectedCourse,
              'total_fees':
                  double.tryParse(_totalFeesController.text.trim()) ?? 0,
              'amount_paid':
                  double.tryParse(_amountPaidController.text.trim()) ?? 0,
              'enrollment_date':
                  _enrollmentDate != null
                      ? Timestamp.fromDate(_enrollmentDate!)
                      : null,
              'payment_due_date': Timestamp.fromDate(_dueDate!),
              'created_at': Timestamp.now(),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Student added successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Add Student', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter student information and payment details',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 20),

              const Text(
                'Student Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildTextField('Student Name *', _nameController, true),
              _buildTextField(
                'Phone Number *',
                _phoneController,
                true,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                'Email',
                _emailController,
                false,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              const Text(
                'Course & Fees',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedCourse,
                hint: const Text('Select Course *'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                items:
                    _courses
                        .map(
                          (course) => DropdownMenuItem(
                            value: course,
                            child: Text(course),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCourse = value;
                  });
                },
                validator:
                    (value) => value == null ? 'Please select a course' : null,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                'Total Fees *',
                _totalFeesController,
                true,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                'Amount Paid',
                _amountPaidController,
                false,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              const Text(
                'Enrollment & Payment',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildDateField(
                label: 'Enrollment Date',
                date: _enrollmentDate,
                onTap: () => _selectDate(context, true),
              ),
              _buildDateField(
                label: 'Payment Due Date *',
                date: _dueDate,
                required: true,
                onTap: () => _selectDate(context, false),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.check),
                    label: const Text('Add Student'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool required, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'This field is required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: TextFormField(
            validator: (_) {
              if (required && date == null) {
                return 'This date is required';
              }
              return null;
            },
            controller: TextEditingController(text: _formatDate(date)),
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
          ),
        ),
      ),
    );
  }
}
