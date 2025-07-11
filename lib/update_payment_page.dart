import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UpdatePaymentPage extends StatefulWidget {
  final Map<String, dynamic> student;
  final String courseName;

  const UpdatePaymentPage({
    super.key,
    required this.student,
    required this.courseName,
  });

  @override
  State<UpdatePaymentPage> createState() => _UpdatePaymentPageState();
}

class _UpdatePaymentPageState extends State<UpdatePaymentPage> {
  late TextEditingController _paymentController;
  String? documentId;

  @override
  void initState() {
    super.initState();
    _paymentController = TextEditingController();
    _fetchDocumentId();
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  /// Get the Firestore document ID once (based on student name and course)
  Future<void> _fetchDocumentId() async {
    final name = widget.student['name'];

    final query =
        await FirebaseFirestore.instance
            .collection('student_enroll_details')
            .where('name', isEqualTo: name)
            .where('course_name', isEqualTo: widget.courseName)
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      setState(() {
        documentId = query.docs.first.id;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Student not found")));
      Navigator.pop(context);
    }
  }

  void _updatePayment(double currentPaid) async {
    final inputAmount = double.tryParse(_paymentController.text.trim()) ?? 0.0;

    if (inputAmount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a valid amount")));
      return;
    }

    final updatedAmount = currentPaid + inputAmount;

    try {
      await FirebaseFirestore.instance
          .collection('student_enroll_details')
          .doc(documentId)
          .update({
            'amount_paid': updatedAmount,
            'last_payment_timestamp': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment updated successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (documentId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('student_enroll_details')
              .doc(documentId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Unnamed';
        final totalFee = (data['total_fees'] ?? 0).toDouble();
        final amountPaid = (data['amount_paid'] ?? 0).toDouble();
        final due = totalFee - amountPaid;
        final percent = totalFee > 0 ? amountPaid / totalFee : 0;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          appBar: AppBar(
            title: const Text('Update Payment'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Student Info
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            widget.courseName,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// Fee Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFeeLabel('Total Fee', totalFee, Colors.black),
                      _buildFeeLabel('Paid', amountPaid, Colors.green),
                      _buildFeeLabel('Due', due, Colors.red),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[300],
                    color: Colors.green,
                    minHeight: 8,
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Payment Amount',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _paymentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter payment amount',
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// Update Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _updatePayment(amountPaid),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.currency_rupee),
                      label: const Text('Update Payment'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// WhatsApp Share Button Placeholder
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Optional: add WhatsApp logic
                      },
                      icon: const Icon(Icons.chat, color: Colors.green),
                      label: const Text('Send PDF Summary via WhatsApp'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeeLabel(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }
}
