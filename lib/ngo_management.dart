import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class NGOManagementPage extends StatefulWidget {
  const NGOManagementPage({super.key});

  @override
  State<NGOManagementPage> createState() => _NGOManagementPageState();
}

class _NGOManagementPageState extends State<NGOManagementPage> {
  final CollectionReference approvedNGOsCollection = FirebaseFirestore.instance.collection('approved-ngos');

  void _removeNGO(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Removal', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove this NGO? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await approvedNGOsCollection.doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NGO removed successfully'),
            backgroundColor: Colors.green.shade600,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing NGO: $e'),
            backgroundColor: Colors.red.shade600,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _viewDetails(String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NGODetailsPage(docId: docId, data: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'NGO Management',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Approved NGOs',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: approvedNGOsCollection.orderBy('timestamp', descending: true).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: SpinKitFadingCircle(color: Colors.blue.shade700));
                }
                final ngos = snapshot.data!.docs;
                if (ngos.isEmpty) {
                  return Center(
                    child: Text(
                      'No approved NGOs found',
                      style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: ngos.length,
                  itemBuilder: (context, index) {
                    final ngo = ngos[index];
                    final data = ngo.data() as Map<String, dynamic>;
                    final ngoName = data['ngoName'] ?? 'N/A';

                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          ngoName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              'Email: ${data['email'] ?? 'N/A'}',
                              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
                            ),
                            Text(
                              'Phone: ${data['phone'] ?? 'N/A'}',
                              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.info, color: Colors.blue.shade700),
                              onPressed: () => _viewDetails(ngo.id, data),
                              tooltip: 'View Details',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red.shade600),
                              onPressed: () => _removeNGO(ngo.id),
                              tooltip: 'Remove NGO',
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

class NGODetailsPage extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const NGODetailsPage({super.key, required this.docId, required this.data});

  Future<int> _getSolvedCasesCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('assignedTo', isEqualTo: data['ngoName'])
        .where('status', isEqualTo: 'Solved')
        .get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    // Format timestamps
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final formattedTimestamp = timestamp != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp)
        : 'N/A';
    final approvedAt = (data['approvedAt'] as Timestamp?)?.toDate();
    final formattedApprovedAt = approvedAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(approvedAt)
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          data['ngoName'] ?? 'NGO Details',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Close',
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'NGO Details',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              SizedBox(height: 16),
              // Details Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('NGO Name', data['ngoName'] ?? 'N/A'),
                      _buildDetailRow('Contact Person', data['contactPerson'] ?? 'N/A'),
                      _buildDetailRow('Email', data['email'] ?? 'N/A'),
                      _buildDetailRow('Phone', data['phone'] ?? 'N/A'),
                      _buildDetailRow('Address', data['address'] ?? 'N/A'),
                      _buildDetailRow('Area of Operation', data['areaOfOperation'] ?? 'N/A'),
                      _buildDetailRow('Services Offered', data['servicesOffered'] ?? 'N/A'),
                      _buildDetailRow('Website', data['website']?.isNotEmpty ?? false ? data['website'] : 'N/A'),
                      _buildDetailRow('Description', data['description'] ?? 'N/A'),
                      _buildDetailRow('Registration Number', data['registrationNumber'] ?? 'N/A'),
                      _buildDetailRow('Status', data['status'] ?? 'N/A'),
                      _buildDetailRow('Submitted On', formattedTimestamp),
                      _buildDetailRow('Approved On', formattedApprovedAt),
                      _buildDetailRow('Password', data['password'] ?? 'N/A'),
                      FutureBuilder<int>(
                        future: _getSolvedCasesCount(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return _buildDetailRow('Cases Solved', 'Loading...');
                          }
                          if (snapshot.hasError) {
                            return _buildDetailRow('Cases Solved', 'Error');
                          }
                          return _buildDetailRow('Cases Solved', snapshot.data.toString(), highlight: true);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: highlight ? Colors.green.shade600 : Colors.grey.shade800,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Divider(color: Colors.grey.shade300),
        ],
      ),
    );
  }
}