import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ngo_registries.dart';
import 'ngo_management.dart';
import 'ngo_password_management.dart';

class NGOAdminPanel extends StatelessWidget {
  const NGOAdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NGORegistriesPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text('NGO Registries', style: GoogleFonts.inter(fontSize: 18)),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NGOManagementPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text('NGO Management', style: GoogleFonts.inter(fontSize: 18)),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NGOPasswordManagementPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text('NGO Password Management', style: GoogleFonts.inter(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}