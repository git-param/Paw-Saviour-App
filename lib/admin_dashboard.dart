import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'admin_report_service.dart';
import 'admin_ngo_widget.dart';
import 'admin_analytics_widget.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => AdminDashboardPageState();
}

class AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const ReportManagementPage(),
    const AnalyticsDashboard(),
    const NGOAdminPanel(),
  ];

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Logout'),
            content: Text('Do you want to logout?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Admin Dashboard', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: Colors.blue.shade700,
        actions: [
            Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: () => setState(() {}),
              ),
            ),
          ],
        ),
        body: _pages[_selectedIndex]
            .animate()
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.2, end: 0, duration: 300.ms),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: 'NGOs'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue.shade700,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}