import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'fee_automation_service.dart';

class PaymentReminderService {
  static Future<void> sendPaymentReminders() async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendPaymentReminders');
      await callable();
    } catch (e) {
      throw 'Failed to send payment reminders: $e';
    }
  }
}
