import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  _AnalyticsDashboardState createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    lastUpdated = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('reports')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: SpinKitFadingCircle(color: Colors.blue));
                  }
                  final reports = snapshot.data!.docs;
                  final total = reports.length;
                  final statusCounts = {
                    'Unsolved': 0,
                    'In Progress': 0,
                    'Solved': 0
                  };
                  final categoryCounts = <String, int>{};

                  for (var report in reports) {
                    final data = report.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'Unsolved';
                    final category = data['category'] ?? 'Unknown';

                    statusCounts[status] = (statusCounts[status] ?? 0) + 1;
                    categoryCounts[category] =
                        (categoryCounts[category] ?? 0) + 1;
                  }

                  final pieChartData = [
                    PieChartSectionData(
                      color: Colors.red,
                      value: statusCounts['Unsolved']!.toDouble(),
                      title: '',
                      radius: 50,
                      badgeWidget: Container(
                        width: 12,
                        height: 12,
                      ),
                      badgePositionPercentageOffset: 1.2,
                    ),
                    PieChartSectionData(
                      color: Colors.yellow,
                      value: statusCounts['In Progress']!.toDouble(),
                      title: '',
                      radius: 50,
                      badgeWidget: Container(
                        width: 12,
                        height: 12,
                      ),
                      badgePositionPercentageOffset: 1.2,
                    ),
                    PieChartSectionData(
                      color: Colors.green,
                      value: statusCounts['Solved']!.toDouble(),
                      title: '',
                      radius: 50,
                      badgeWidget: Container(
                        width: 12,
                        height: 12,
                      ),
                      badgePositionPercentageOffset: 1.2,
                    ),
                  ];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reports Analysis',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Last Updated: ${lastUpdated?.toString().substring(0, 19) ?? 'N/A'}',
                          style: GoogleFonts.inter(
                              fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Reports: $total',
                                    style: GoogleFonts.inter(fontSize: 18)),
                                const SizedBox(height: 16),
                                Text('Status:',
                                    style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                                ...statusCounts.entries.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: e.key == 'Unsolved'
                                                ? Colors.red
                                                : e.key == 'In Progress'
                                                    ? Colors.yellow
                                                    : Colors.green,
                                            shape: BoxShape.rectangle,
                                          ),
                                        ),
                                        Text(
                                          '${e.key}: ${e.value}',
                                          style:
                                              GoogleFonts.inter(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: PieChart(
                                    PieChartData(
                                      sections: pieChartData,
                                      centerSpaceRadius: 40,
                                      sectionsSpace: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Categories:',
                                    style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                                ...categoryCounts.entries.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Text(
                                      '${e.key}: ${e.value}',
                                      style: GoogleFonts.inter(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
