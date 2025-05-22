import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'ngo_approval_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class NGORegistriesPage extends StatefulWidget {
  const NGORegistriesPage({super.key});

  @override
  State<NGORegistriesPage> createState() => _NGORegistriesPageState();
}

class _NGORegistriesPageState extends State<NGORegistriesPage> {
  final CollectionReference ngoCollection =
      FirebaseFirestore.instance.collection('registration-queries');
  final NGOApprovalService _approvalService = NGOApprovalService();
  final Map<String, bool> _selectedNGOs = {};
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  bool _isApproving = false;

  void _toggleSelection(String docId) =>
      setState(() => _selectedNGOs[docId] = !(_selectedNGOs[docId] ?? false));

  void _bulkAccept() async {
    if (_selectedNGOs.isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('No NGOs selected for approval'),
          backgroundColor: Colors.orange.shade600,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    for (var docId in _selectedNGOs.keys.where((id) => _selectedNGOs[id]!)) {
      try {
        final doc = await ngoCollection.doc(docId).get();
        if (!doc.exists) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('NGO $docId no longer exists'),
              backgroundColor: Colors.red.shade600,
              duration: Duration(seconds: 3),
            ),
          );
          continue;
        }
        final data = doc.data() as Map<String, dynamic>;
        print('Approving NGO $docId with data: $data');
        final result = await _approvalService.approveNGO(docId, data);
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              result.contains('email sent successfully')
                  ? 'NGO ${data['ngoName'] ?? data['name'] ?? docId} approved, email sent!'
                  : 'NGO ${data['ngoName'] ?? data['name'] ?? docId} approved, email failed: ${result.split(': ').last}',
            ),
            backgroundColor: result.contains('email sent successfully')
                ? Colors.green.shade600
                : Colors.red.shade600,
            duration: Duration(seconds: 4),
          ),
        );
      } catch (e) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Error approving NGO $docId: $e'),
            backgroundColor: Colors.red.shade600,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
    setState(() => _selectedNGOs.clear());
  }

  void _bulkReject() async {
    if (_selectedNGOs.isEmpty) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('No NGOs selected for rejection'),
          backgroundColor: Colors.orange.shade600,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    for (var docId in _selectedNGOs.keys.where((id) => _selectedNGOs[id]!)) {
      try {
        await ngoCollection.doc(docId).delete();
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('NGO $docId rejected successfully'),
            backgroundColor: Colors.green.shade600,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Error rejecting NGO $docId: $e'),
            backgroundColor: Colors.red.shade600,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
    setState(() => _selectedNGOs.clear());
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('NGO Registries', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: Colors.blue.shade700,
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('NGO Registration Requests', style: GoogleFonts.inter(fontSize: 17)),
                  if (_selectedNGOs.values.any((selected) => selected))
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isApproving ? null : _bulkAccept,
                          child: _isApproving
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _bulkReject,
                          child: Text('Reject', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: ngoCollection.orderBy('timestamp', descending: true).snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: SpinKitFadingCircle(color: Colors.blue.shade700));
                  }
                  final ngos = snapshot.data!.docs;
                  if (ngos.isEmpty) {
                    return Center(child: Text('No registration requests found'));
                  }
                  return ListView.builder(
                    itemCount: ngos.length,
                    itemBuilder: (context, index) {
                      final ngo = ngos[index];
                      final data = ngo.data() as Map<String, dynamic>;
                      print('NGO Data for ${ngo.id}: $data'); // Debug print
                      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                      final formattedTimestamp = timestamp != null
                          ? DateFormat('MMM dd, yyyy - HH:mm').format(timestamp)
                          : 'N/A';
                      final ngoName = data['ngoName'] ?? data['name'] ?? 'N/A';

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: Checkbox(
                            value: _selectedNGOs[ngo.id] ?? false,
                            onChanged: (value) => _toggleSelection(ngo.id),
                          ),
                          title: Text(ngoName, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${data['status'] ?? 'Pending'}'),
                              Text('Email: ${data['email'] ?? 'N/A'}'),
                              Text('Phone: ${data['phone'] ?? 'N/A'}'),
                              Text('Submitted: $formattedTimestamp'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (data['status'] == 'pending') ...[
                                IconButton(
                                  icon: _isApproving
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.green,
                                          ),
                                        )
                                      : Icon(Icons.check, color: Colors.green),
                                  onPressed: _isApproving
                                      ? null
                                      : () async {
                                          setState(() => _isApproving = true);
                                          try {
                                            final result = await _approvalService.approveNGO(ngo.id, data);
                                            _scaffoldMessengerKey.currentState?.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  result.contains('email sent successfully')
                                                      ? 'NGO $ngoName approved, email sent!'
                                                      : 'NGO $ngoName approved, email failed: ${result.split(': ').last}',
                                                ),
                                                backgroundColor: result.contains('email sent successfully')
                                                    ? Colors.green.shade600
                                                    : Colors.red.shade600,
                                                duration: Duration(seconds: 4),
                                              ),
                                            );
                                          } catch (e) {
                                            _scaffoldMessengerKey.currentState?.showSnackBar(
                                              SnackBar(
                                                content: Text('Error approving NGO $ngoName: $e'),
                                                backgroundColor: Colors.red.shade600,
                                                duration: Duration(seconds: 4),
                                              ),
                                            );
                                          }
                                          setState(() => _isApproving = false);
                                        },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () async {
                                    try {
                                      await ngoCollection.doc(ngo.id).delete();
                                      _scaffoldMessengerKey.currentState?.showSnackBar(
                                        SnackBar(
                                          content: Text('NGO $ngoName rejected successfully'),
                                          backgroundColor: Colors.green.shade600,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    } catch (e) {
                                      _scaffoldMessengerKey.currentState?.showSnackBar(
                                        SnackBar(
                                          content: Text('Error rejecting NGO $ngoName: $e'),
                                          backgroundColor: Colors.red.shade600,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
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
      ),
    );
  }
}