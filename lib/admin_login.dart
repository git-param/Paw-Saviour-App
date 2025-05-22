import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminLoginPage extends StatefulWidget 
{
  const AdminLoginPage({super.key});
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> 
{
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _idFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() 
  {
    _idController.dispose();
    _passwordController.dispose();
    _idFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loginAdmin() async 
  {
    if (!_formKey.currentState!.validate()) 
      return;
    setState(() => _isLoading = true);
    try 
    {
      final adminId = _idController.text.trim();
      final password = _passwordController.text.trim();
      final docRef = FirebaseFirestore.instance.collection('admins').doc(adminId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) throw Exception('No admin found with this ID');
      if (docSnapshot.data()!['password'] != password) throw Exception('Incorrect password');

      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } 
    catch (e) 
    {
      ScaffoldMessenger.of(context).showSnackBar
      (
        SnackBar
        (
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } 
    finally 
    {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold
    (
      backgroundColor: Colors.blue.shade700,
      body: SafeArea
      (
        child: Center
        (
          child: SingleChildScrollView
          (
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column
            (
              mainAxisAlignment: MainAxisAlignment.center,
              children: 
              [
                Icon(Icons.pets, size: 90, color: Colors.white),
                SizedBox(height: 20),
                Text
                (
                  'Admin Login',
                  style: GoogleFonts.inter
                  (
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text
                (
                  'Login to your admin account',
                  style: GoogleFonts.inter
                  (
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 40),
                Container
                (
                  padding: EdgeInsets.all(24.0),
                  decoration: BoxDecoration
                  (
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: 
                    [
                      BoxShadow
                      (
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form
                  (
                    key: _formKey,
                    child: Column
                    (
                      children: 
                      [
                        TextFormField
                        (
                          controller: _idController,
                          focusNode: _idFocusNode,
                          decoration: InputDecoration
                          (
                            labelText: 'Admin ID',
                            prefixIcon: Icon(Icons.person, color: Colors.blue),
                            border: OutlineInputBorder
                            (
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocusNode),
                          validator: (value) 
                          {
                            if (value == null || value.isEmpty) return 'Please enter your Admin ID';
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField
                        (
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          decoration: InputDecoration
                          (
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock, color: Colors.blue),
                            suffixIcon: IconButton
                            (
                              icon: Icon
                              (
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.blue,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder
                            (
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _loginAdmin(),
                          validator: (value)
                          {
                            if (value == null || value.isEmpty) 
                              return 'Please enter your password';
                            if (value.length < 6) 
                              return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        _isLoading? SpinKitFadingCircle(color: Colors.blue.shade700, size: 50)
                            : ElevatedButton
                            (
                                onPressed: _loginAdmin,
                                style: ElevatedButton.styleFrom
                                (
                                  minimumSize: Size(double.infinity, 50),
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder
                                  (
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 3,
                                ),
                                child: Text
                                (
                                  'Login',
                                  style: GoogleFonts.inter
                                  (
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ).animate().fadeIn(duration: 300.ms),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}