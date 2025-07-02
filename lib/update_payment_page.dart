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

  @override
  void initState() {
    super.initState();
    _paymentController = TextEditingController();
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  void updatePayment() async {
    final String studentName = widget.student['name'];

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('student_enroll_details')
              .where('name', isEqualTo: studentName)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student not found in Firestore')),
        );
        return;
      }

      final doc = querySnapshot.docs.first;
      final currentPaid = (doc['amount_paid'] ?? 0).toDouble();
      final inputAmount = double.tryParse(_paymentController.text) ?? 0.0;
      final updatedPaid = currentPaid + inputAmount;

      await FirebaseFirestore.instance
          .collection('student_enroll_details')
          .doc(doc.id)
          .update({
            'amount_paid': updatedPaid,
            'last_payment_timestamp': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment updated successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double total = (widget.student['total_fee'] ?? 0).toDouble();
    final double paid = (widget.student['amount_paid'] ?? 0).toDouble();
    final double due = total - paid;
    final double percent = total > 0 ? paid / total : 0;

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
                        widget.student['name'] ?? 'No Name',
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

              /// Fee Breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFeeLabel('Total Fee', total, Colors.black),
                  _buildFeeLabel('Paid', paid, Colors.green),
                  _buildFeeLabel('Due', due, Colors.red),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: percent > 1 ? 1 : percent,
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
                  onPressed: updatePayment,
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

              /// WhatsApp Summary Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Optional: WhatsApp integration logic
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
