import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FeeAutomationService {
  static Future<File> generateFeeInvoice({
    required String studentName,
    required String courseName,
    required double totalFees,
    required double amountPaid,
    required DateTime enrollmentDate,
    required DateTime dueDate,
    required String phoneNumber,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    final pendingAmount = totalFees - amountPaid;
    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('Course Fee Invoice')),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Invoice Number: $invoiceNumber'),
                      pw.Text('Date: ${dateFormat.format(DateTime.now())}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Student: $studentName'),
                      pw.Text('Course: $courseName'),
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
                    children: [
                      pw.Padding(
                        child: pw.Text(
                          'Description',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        padding: pw.EdgeInsets.all(8),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        padding: pw.EdgeInsets.all(8),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        child: pw.Text('Total Course Fees'),
                        padding: pw.EdgeInsets.all(8),
                      ),
                      pw.Padding(
                        child: pw.Text(currencyFormat.format(totalFees)),
                        padding: pw.EdgeInsets.all(8),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        child: pw.Text('Amount Paid'),
                        padding: pw.EdgeInsets.all(8),
                      ),
                      pw.Padding(
                        child: pw.Text(currencyFormat.format(amountPaid)),
                        padding: pw.EdgeInsets.all(8),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        child: pw.Text(
                          'Pending Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        padding: pw.EdgeInsets.all(8),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          currencyFormat.format(pendingAmount),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        padding: pw.EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Payment Due Date: ${dateFormat.format(dueDate)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Enrollment Date: ${dateFormat.format(enrollmentDate)}'),
              pw.SizedBox(height: 30),
              pw.Text('Payment Instructions:'),
              pw.Text('1. Please pay before due date to avoid late fees.'),
              pw.Text(
                '2. Payment can be made via UPI, Bank Transfer, or Cash.',
              ),
              pw.Text('3. Contact institute for payment queries.'),
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

  static Future<void> sendWhatsAppMessage({
    required String phoneNumber,
    required String message,
    required File attachment,
  }) async {
    // Clean phone number (remove any non-digit characters)
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // First try with country code (assuming India +91)
    String url =
        'https://wa.me/91$cleanPhone?text=${Uri.encodeComponent(message)}';

    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        // Fallback to regular WhatsApp URL
        url =
            'whatsapp://send?phone=91$cleanPhone&text=${Uri.encodeComponent(message)}';
        await launch(url);
      }
    } catch (e) {
      throw 'Could not launch WhatsApp: $e';
    }
  }

  static Future<void> sendFeeInvoice({
    required BuildContext context,
    required String studentName,
    required String courseName,
    required double totalFees,
    required double amountPaid,
    required DateTime enrollmentDate,
    required DateTime dueDate,
    required String phoneNumber,
  }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate PDF
      final pdfFile = await generateFeeInvoice(
        studentName: studentName,
        courseName: courseName,
        totalFees: totalFees,
        amountPaid: amountPaid,
        enrollmentDate: enrollmentDate,
        dueDate: dueDate,
        phoneNumber: phoneNumber,
      );

      // Prepare message
      final message = '''
Hello $studentName,

Your invoice for $courseName is attached. 

Total Fees: ₹$totalFees
Amount Paid: ₹$amountPaid
Pending Amount: ₹${totalFees - amountPaid}
Due Date: ${DateFormat('dd MMM yyyy').format(dueDate)}

Please complete the payment before due date.
Thank you!
      ''';

      // Close loading dialog
      Navigator.of(context).pop();

      // Send via WhatsApp
      await sendWhatsAppMessage(
        phoneNumber: phoneNumber,
        message: message,
        attachment: pdfFile,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice sent successfully via WhatsApp')),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send invoice: $e')));
    }
  }
}
