import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'google_drive_service.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class ReportPageWidget extends StatefulWidget {
  const ReportPageWidget({super.key});

  @override
  State<ReportPageWidget> createState() => _ReportPageWidgetState();
}

class _ReportPageWidgetState extends State<ReportPageWidget> {
  File? _image;
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  Position? _currentPosition;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  String? _audioPath;
  bool _isRecording = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _recordAudio() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      if (_isRecording) {
        final path = await _recorder.stopRecorder();
        setState(() {
          _audioPath = path;
          _isRecording = false;
        });
      } else {
        await _recorder.startRecorder(toFile: 'audio_record.aac');
        setState(() {
          _isRecording = true;
        });
      }
    } else {
      _showSnackBar('Microphone permission required', Colors.red);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _getLocation() async {
    var status = await Permission.location.request();
    if (!status.isGranted) {
      _showSnackBar('Location permission required', Colors.red);
      return;
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }

  Future<String> _getNextCaseId() async {
    var reports = await FirebaseFirestore.instance
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (reports.docs.isEmpty) {
      return 'case-1';
    } else {
      String lastCaseId = reports.docs.first.id;
      int caseNumber = int.parse(lastCaseId.split('-')[1]);
      return 'case-${caseNumber + 1}';
    }
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate() && _image != null && _currentPosition != null) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        String caseId = await _getNextCaseId();
        GoogleDriveService googleDriveService = GoogleDriveService();
        await googleDriveService.authenticateWithGoogleDrive();
        String folderUrl = await googleDriveService.createCaseFolder(caseId);
        String folderId = folderUrl.split('/folders/')[1];

        String? imageUrl;
        String? audioUrl;
        imageUrl = await googleDriveService.uploadFileToCaseFolder(_image!, folderId);
        if (_audioPath != null) {
          File audioFile = File(_audioPath!);
          if (await audioFile.exists()) {
            audioUrl = await googleDriveService.uploadFileToCaseFolder(audioFile, folderId);
          } else {
            _showSnackBar('Audio file not found.', Colors.red);
            return;
          }
        }

        await FirebaseFirestore.instance.collection('reports').doc(caseId).set({
          'caseId': caseId,
          'folderUrl': folderUrl,
          'imageUrl': imageUrl,
          'audioUrl': audioUrl,
          'category': _selectedCategory,
          'description': _descriptionController.text.trim(),
          'location': {
            'latitude': _currentPosition!.latitude,
            'longitude': _currentPosition!.longitude,
          },
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Unsolved',
        });

        setState(() {
          _image = null;
          _audioPath = null;
          _isRecording = false;
          _selectedCategory = null;
          _descriptionController.clear();
          _currentPosition = null;
        });

        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        _showSnackBar('Error submitting report: $e', Colors.red);
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    } else {
      if (_image == null) {
        _showSnackBar('Please capture an image.', Colors.red);
      }
      if (_currentPosition == null) {
        _showSnackBar('Please share your location.', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Report an Incident'),
          backgroundColor: Colors.blue,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 20),
                      color: Colors.blue,
                      child: Column(
                        children: [
                          Icon(
                            Icons.report,
                            color: Colors.white,
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Report an Incident',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          _image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(_image!, height: 150, width: 150, fit: BoxFit.cover),
                                )
                              : Text('No image selected', style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _pickImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Icon(Icons.camera_alt, color: Colors.white),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _recordAudio,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
                              ),
                              if (_audioPath != null) SizedBox(width: 12),
                              if (_audioPath != null)
                                ElevatedButton(
                                  onPressed: () async {
                                    await _player.startPlayer(fromURI: _audioPath);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Icon(Icons.play_arrow, color: Colors.white),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: [
                        'Animal Abuse',
                        'Animal Accident',
                        'Animal Health Issue',
                        'Wild Animal'
                      ]
                          .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Select Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _getLocation,
                      icon: Icon(Icons.location_on, color: Colors.white),
                      label: Text(
                        _currentPosition != null
                            ? 'Location: (${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)})'
                            : 'Share Location',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Submit Report',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}