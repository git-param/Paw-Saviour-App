import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:uuid/uuid.dart';

class NGOPasswordManagementPage extends StatefulWidget {
  const NGOPasswordManagementPage({super.key});

  @override
  State<NGOPasswordManagementPage> createState() => _NGOPasswordManagementPageState();
}

class _NGOPasswordManagementPageState extends State<NGOPasswordManagementPage> {
  final CollectionReference resetRequests = FirebaseFirestore.instance.collection('password_reset_requests');
  final CollectionReference approvedNGOs = FirebaseFirestore.instance.collection('approved-ngos');

  Future<String> _sendPasswordResetEmail(String email, String ngoName, String newPassword) async {
    final smtpServer = gmail('paramdholakia1@gmail.com', 'hwlg gckb oskt ikeb');
    final message = Message()
      ..from = Address('paramdholakia1@gmail.com', 'Paw Saviour Admin')
      ..recipients.add(email)
      ..subject = 'Paw Saviour: Password Reset'
      ..text = '''
Dear $ngoName,

Your password for the Paw Saviour app has been reset.

Your new password is: $newPassword

Please log in and change your password immediately.

Best regards,
Paw Saviour Admin
'''
      ..html = '''
<h3>Paw Saviour: Password Reset</h3>
<p>Dear $ngoName,</p>
<p>Your password for the Paw Saviour app has been reset.</p>
<ul>
  <li><strong>New Password:</strong> $newPassword</li>
</ul>
<p>Please log in and change your password immediately.</p>
<p>Best regards,<br>Paw Saviour Admin</p>
''';

    int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        await send(message, smtpServer);
        return 'Email sent successfully';
      } catch (e) {
        retryCount++;
        if (retryCount == maxRetries) {
          return 'Failed to send email after $maxRetries attempts: $e';
        }
        await Future.delayed(Duration(milliseconds: 1000 * retryCount));
      }
    }
    return 'Failed to send email: Reached retry limit';
  }

  Future<void> _resetPassword(String email, String requestId) async {
    final String newPassword = Uuid().v4().substring(0, 8);
    final querySnapshot = await approvedNGOs.where('email', isEqualTo: email).limit(1).get();

    if (querySnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No approved NGO found with this email'), backgroundColor: Colors.red),
      );
      return;
    }

    final ngoDoc = querySnapshot.docs.first;
    final ngoName = ngoDoc['name'] ?? 'NGO';
    await approvedNGOs.doc(ngoDoc.id).update({'password': newPassword});
    await resetRequests.doc(email).update({'status': 'completed'});

    String emailResult = await _sendPasswordResetEmail(email, ngoName, newPassword);

    if (emailResult.startsWith('Failed')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset. Email failed: ${emailResult.split(': ')[1]}. New password: $newPassword'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset and email sent successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    }

    setState(() {});
  }

  Future<void> _rejectRequest(String email) async {
    await resetRequests.doc(email).update({'status': 'rejected'});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NGO Password Management', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Password Reset Requests', style: GoogleFonts.inter(fontSize: 22)),
          ),
          Expanded(
            child: StreamBuilder(
              stream: resetRequests.where('status', isEqualTo: 'pending').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return Center(child: SpinKitFadingCircle(color: Colors.blue.shade700));
                final requests = snapshot.data!.docs;
                if (requests.isEmpty) return Center(child: Text('No pending password reset requests'));
                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final data = request.data() as Map<String, dynamic>;
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                    final formattedTimestamp = timestamp != null
                        ? DateFormat('MMM dd, yyyy - HH:mm').format(timestamp)
                        : 'N/A';

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text('Email: ${data['email'] ?? 'N/A'}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${data['status'] ?? 'Pending'}'),
                            Text('Requested: $formattedTimestamp'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () => _resetPassword(data['email'], request.id),
                              tooltip: 'Reset Password',
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectRequest(data['email']),
                              tooltip: 'Reject Request',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}