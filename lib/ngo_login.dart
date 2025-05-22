import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NGOLoginPage extends StatefulWidget {
  const NGOLoginPage({super.key});

  @override
  State<NGOLoginPage> createState() => _NGOLoginPageState();
}

class _NGOLoginPageState extends State<NGOLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loginNGO() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final querySnapshot = await FirebaseFirestore.instance
          .collection('approved-ngos')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) throw Exception('No approved NGO found with this email');

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      if (data['password'] != password) throw Exception('Incorrect password');

      final ngoName = doc.id;

      Navigator.pushReplacementNamed(context, '/ngo_dashboard', arguments: ngoName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPasswordReset() async {
    final String email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('password_reset_requests').doc(email).set({
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset request submitted. Admin will contact you.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, size: 90, color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'NGO Login',
                  style: GoogleFonts.inter(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Login to your NGO account',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 40),
                Container(
                  padding: EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email, color: Colors.blue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocusNode),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your email';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock, color: Colors.blue),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.blue,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _loginNGO(),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your password';
                            if (value.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _requestPasswordReset,
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.inter(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        _isLoading
                            ? SpinKitFadingCircle(color: Colors.blue.shade700, size: 50)
                            : ElevatedButton(
                                onPressed: _loginNGO,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(double.infinity, 50),
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 3,
                                ),
                                child: Text(
                                  'Login',
                                  style: GoogleFonts.inter(
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