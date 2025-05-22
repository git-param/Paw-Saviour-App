import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPageWidget extends StatefulWidget {
  const RegisterPageWidget({super.key});

  @override
  State<RegisterPageWidget> createState() => _RegisterPageWidgetState();
}

class _RegisterPageWidgetState extends State<RegisterPageWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaOfOperationController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedService;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _areaOfOperationController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        String name = _nameController.text.trim();

        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('registration-queries')
            .doc(name)
            .get();

        if (doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An organization with this name already exists!'),
              backgroundColor: Colors.red.shade600,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        await FirebaseFirestore.instance
            .collection('registration-queries')
            .doc(name)
            .set({
          'name': name,
          'contactPerson': _contactPersonController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'areaOfOperation': _areaOfOperationController.text.trim(),
          'servicesOffered': _selectedService,
          'website': _websiteController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration submitted successfully! Awaiting admin approval.'),
            backgroundColor: Colors.green.shade600,
            duration: Duration(seconds: 3),
          ),
        );

        setState(() {
          _nameController.clear();
          _contactPersonController.clear();
          _emailController.clear();
          _phoneController.clear();
          _addressController.clear();
          _areaOfOperationController.clear();
          _websiteController.clear();
          _descriptionController.clear();
          _selectedService = null;
        });

        await Future.delayed(Duration(seconds: 3));
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting registration: $e'),
            backgroundColor: Colors.red.shade600,
            duration: Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Organization Registration'),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade700, Colors.teal.shade500],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.group_add,
                    color: Colors.white,
                    size: 60,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Register Your Organization',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Organization Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the organization name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _contactPersonController,
                          decoration: InputDecoration(
                            labelText: 'Contact Person',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the contact person\'s name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an email address';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a phone number';
                            }
                            if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                              return 'Phone number must be exactly 10 digits';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the address';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _areaOfOperationController,
                          decoration: InputDecoration(
                            labelText: 'Area of Operation (e.g., City, State)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the area of operation';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedService,
                          items: [
                            DropdownMenuItem(value: 'Animal Rescue', child: Text('Animal Rescue')),
                            DropdownMenuItem(value: 'Veterinary Care', child: Text('Veterinary Care')),
                            DropdownMenuItem(value: 'Adoption Services', child: Text('Adoption Services')),
                            DropdownMenuItem(value: 'Awareness Campaigns', child: Text('Awareness Campaigns')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedService = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Services Offered',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a service';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _websiteController,
                          decoration: InputDecoration(
                            labelText: 'Website URL (Optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.url,
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              if (!RegExp(r'^(https?:\/\/)?([\w-]+\.)+[\w-]{2,4}(\/.*)?$').hasMatch(value)) {
                                return 'Please enter a valid URL';
                              }
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description of Organization (Mission/Purpose)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a description of the organization';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        Center(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitRegistration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Submit Registration',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}