import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;

class NGOApprovalService {
  // Generate a random password
  String _generateRandomPassword() {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
          12, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // Validate email address format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Send email to the NGO with login credentials
  Future<String> _sendApprovalEmail(
      String? email, String? ngoName, String password) async {
    if (email == null || ngoName == null) {
      print('Error: Email or NGO name is null');
      return 'Failed to send email: Missing email or NGO name';
    }

    if (!_isValidEmail(email)) {
      print('Error: Invalid email format - $email');
      return 'Failed to send email: Invalid email format';
    }

    if (kIsWeb) {
      print('Error: Email sending not supported on web platform');
      return 'Failed to send email: Web platform not supported';
    }

    print('Attempting to send email via Gmail SMTP to $email');
    final smtpServer = gmail('paramdholakia1@gmail.com', 'hwlg gckb oskt ikeb');

    final message = Message()
      ..from = const Address('paramdholakia1@gmail.com', 'Paw Saviour Admin')
      ..recipients.add(email)
      ..subject = 'Paw Saviour: NGO Registration Approved'
      ..text = '''
Dear $ngoName,

We are pleased to inform you that your NGO registration with Paw Saviour has been approved!

You can now log in to the Paw Saviour platform using the following credentials:
- Login ID: $email
- Password: $password

Please keep this password secure and do not share it with others. You can change your password after logging in if needed.

To log in, visit the Paw Saviour app and use the "NGO Login" option.

If you have any questions or need assistance, feel free to contact us at meetd19174@gmail.com.

Thank you for joining us in our mission to help animals in need!

Best regards,
The Paw Saviour Team
'''
      ..html = '''
<h3>Paw Saviour: NGO Registration Approved</h3>
<p>Dear $ngoName,</p>
<p>We are pleased to inform you that your NGO registration with Paw Saviour has been approved!</p>
<p>You can now log in to the Paw Saviour platform using the following credentials:</p>
<ul>
  <li><strong>Login ID:</strong> $email</li>
  <li><strong>Password:</strong> $password</li>
</ul>
<p>Please keep this password secure and do not share it with others. You can change your password after logging in if needed.</p>
<p>To log in, visit the Paw Saviour app and use the "NGO Login" option.</p>
<p>If you have any questions or need assistance, feel free to contact us at <a href="mailto:meetd19174@gmail.com">meetd19174@gmail.com</a>.</p>
<p>Thank you for joining us in our mission to help animals in need!</p>
<p>Best regards,<br>The Paw Saviour Team</p>
''';

    int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final sendReport = await send(message, smtpServer);
        print('Email sent successfully to $email: ${sendReport.toString()}');
        return 'Email sent successfully';
      } catch (e) {
        retryCount++;
        print('SMTP Attempt $retryCount failed to send email to $email: $e');
        print('Stack trace: ${StackTrace.current}');
        if (retryCount == maxRetries) {
          return 'Failed to send email after $maxRetries attempts: $e';
        }
        await Future.delayed(Duration(milliseconds: 1000 * retryCount));
      }
    }
    return 'Failed to send email: Reached retry limit';
  }

  // Approve the NGO: Move to approved-ngos, generate password, and attempt to send email
  Future<String> approveNGO(String ngoId, Map<String, dynamic> ngoData) async {
    try {
      // Normalize field names (use 'name' if 'ngoName' is missing)
      ngoData['ngoName'] = ngoData['ngoName'] ?? ngoData['name'];
      
      // Validate required fields
      if (ngoData['email'] == null || ngoData['ngoName'] == null) {
        print('Error: Missing required fields in ngoData: $ngoData');
        throw Exception('Missing email or NGO name in data');
      }

      // Generate a random password
      String generatedPassword = _generateRandomPassword();

      // Add the generated password and approval timestamp to the NGO data
      ngoData['password'] = generatedPassword;
      ngoData['approvedAt'] = FieldValue.serverTimestamp();
      ngoData['status'] = 'approved';

      // Move the NGO to the approved-ngos collection
      print('Adding NGO to approved-ngos: $ngoId');
      await FirebaseFirestore.instance
          .collection('approved-ngos')
          .doc(ngoId)
          .set(ngoData);

      // Delete the NGO from the registration-queries collection
      print('Deleting NGO from registration-queries: $ngoId');
      await FirebaseFirestore.instance
          .collection('registration-queries')
          .doc(ngoId)
          .delete();

      // Attempt to send the approval email
      print('Sending approval email to: ${ngoData['email']}');
      String emailResult = await _sendApprovalEmail(
          ngoData['email'], ngoData['ngoName'], generatedPassword);

      if (emailResult.startsWith('Failed')) {
        print('NGO approved, but email failed: $emailResult');
        return 'NGO approved, but failed to send email: ${emailResult.split(': ')[1]}';
      }

      print('NGO approved and email sent successfully for $ngoId');
      return 'NGO approved and email sent successfully';
    } catch (e) {
      print('Error in approveNGO for $ngoId: $e');
      throw Exception('Error approving NGO: $e');
    }
  }

  // Test email function for debugging
  Future<String> testEmail(String testEmail, String testNgoName) async {
    String password = _generateRandomPassword();
    return await _sendApprovalEmail(testEmail, testNgoName, password);
  }
}