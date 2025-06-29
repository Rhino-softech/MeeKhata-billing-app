import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

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

  final List<String> _courses = [
    'CCNA Course',
    'CCNP Course',
    'CCIE Course',
    'Data Analytics Course',
    'AWS Solution Architect Course',
    'Cybersecurity Course',
    'CompTIA Security Course',
    'Certified Ethical Hacking',
    'AWS DevOps Course',
    'Azure DevOps Course',
    'Linux Administration',
    'Python Full Stack',
    'Java Full Stack',
  ];

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

  Future<File> _generateFeeInvoice() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    final totalFees = double.tryParse(_totalFeesController.text.trim()) ?? 0;
    final amountPaid = double.tryParse(_amountPaidController.text.trim()) ?? 0;
    final pendingAmount = totalFees - amountPaid;
    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Course Fee Invoice',
                  style: pw.TextStyle(fontSize: 24),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Invoice Number: $invoiceNumber',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Date: ${dateFormat.format(DateTime.now())}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Student: ${_nameController.text.trim()}'),
                      pw.Text('Course: $_selectedCourse'),
                    ],
                  ),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        child: pw.Text(
                          'Description',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        child: pw.Text('Total Course Fees'),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                      pw.Padding(
                        child: pw.Text(currencyFormat.format(totalFees)),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        child: pw.Text('Amount Paid'),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                      pw.Padding(
                        child: pw.Text(currencyFormat.format(amountPaid)),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        child: pw.Text(
                          'Pending Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          currencyFormat.format(pendingAmount),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Payment Due Date: ${dateFormat.format(_dueDate!)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Enrollment Date: ${_enrollmentDate != null ? dateFormat.format(_enrollmentDate!) : 'Not specified'}',
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Payment Instructions:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('1. Please pay before due date to avoid late fees.'),
              pw.Text(
                '2. Payment can be made via UPI, Bank Transfer, or Cash.',
              ),
              pw.Text('3. Contact institute for payment queries.'),
              pw.SizedBox(height: 20),
              pw.Text(
                'Thank you for choosing our institute!',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$invoiceNumber.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> _sendWhatsAppInvoice() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate PDF
      final pdfFile = await _generateFeeInvoice();

      // Prepare message
      final totalFees = double.tryParse(_totalFeesController.text.trim()) ?? 0;
      final amountPaid =
          double.tryParse(_amountPaidController.text.trim()) ?? 0;

      final message = '''
Hello ${_nameController.text.trim()},

Your invoice for $_selectedCourse is attached. 

📌 *Payment Details:*
- Total Fees: ₹$totalFees
- Amount Paid: ₹$amountPaid
- Pending Amount: ₹${totalFees - amountPaid}
- Due Date: ${DateFormat('dd MMM yyyy').format(_dueDate!)}

Please complete the payment before due date to avoid late fees.

Thank you!
*[Your Institute Name]*
      ''';

      // Clean phone number (remove any non-digit characters)
      final cleanPhone = _phoneController.text.trim().replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      // First try with country code (assuming India +91)
      String url =
          'https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(message)}';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        // Fallback to regular WhatsApp URL
        url =
            'whatsapp://send?phone=91$cleanPhone&text=${Uri.encodeComponent(message)}';
        await launchUrl(Uri.parse(url));
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice sent successfully via WhatsApp'),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invoice: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        final totalFees =
            double.tryParse(_totalFeesController.text.trim()) ?? 0;
        final amountPaid =
            double.tryParse(_amountPaidController.text.trim()) ?? 0;

        await FirebaseFirestore.instance
            .collection('student_enroll_details')
            .add({
              'name': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'email': _emailController.text.trim(),
              'course': _selectedCourse,
              'total_fees': totalFees,
              'amount_paid': amountPaid,
              'pending_amount': totalFees - amountPaid,
              'enrollment_date':
                  _enrollmentDate != null
                      ? Timestamp.fromDate(_enrollmentDate!)
                      : null,
              'payment_due_date': Timestamp.fromDate(_dueDate!),
              'created_at': Timestamp.now(),
              'payment_status': amountPaid >= totalFees ? 'Paid' : 'Pending',
              'last_reminder_sent': null,
            });

        // Send invoice via WhatsApp
        await _sendWhatsAppInvoice();

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Student added and invoice sent successfully'),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('❌ Error: ${e.toString()}')));
        }
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

              // Student Information Section
              _buildSectionHeader('Student Information'),
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

              // Course & Fees Section
              _buildSectionHeader('Course & Fees'),
              _buildCourseDropdown(),
              const SizedBox(height: 12),
              _buildTextField(
                'Total Fees *',
                _totalFeesController,
                true,
                keyboardType: TextInputType.number,
                prefixText: '₹ ',
              ),
              _buildTextField(
                'Amount Paid',
                _amountPaidController,
                false,
                keyboardType: TextInputType.number,
                prefixText: '₹ ',
              ),

              const SizedBox(height: 20),

              // Enrollment & Payment Section
              _buildSectionHeader('Enrollment & Payment'),
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
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool required, {
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
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
          if (keyboardType == TextInputType.phone && value!.length < 10) {
            return 'Enter a valid phone number';
          }
          if (keyboardType == TextInputType.emailAddress &&
              value!.isNotEmpty &&
              !value.contains('@')) {
            return 'Enter a valid email';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixText: prefixText,
        ),
      ),
    );
  }

  Widget _buildCourseDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCourse,
      hint: const Text('Select Course *'),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items:
          _courses
              .map(
                (course) =>
                    DropdownMenuItem(value: course, child: Text(course)),
              )
              .toList(),
      onChanged: (value) => setState(() => _selectedCourse = value),
      validator: (value) => value == null ? 'Please select a course' : null,
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _submitForm,
          icon: const Icon(Icons.check),
          label: const Text('Add Student'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _totalFeesController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }
}
