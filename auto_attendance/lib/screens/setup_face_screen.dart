import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import '../services/face_recognition_api.dart';

class SetupFaceScreen extends StatefulWidget {
  const SetupFaceScreen({super.key});

  @override
  State<SetupFaceScreen> createState() => _SetupFaceScreenState();
}

class _SetupFaceScreenState extends State<SetupFaceScreen> {
  Uint8List? _leftImageBytes;
  Uint8List? _rightImageBytes;
  Uint8List? _frontImageBytes;

  String? _leftImageName;
  String? _rightImageName;
  String? _frontImageName;

  final _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage(String position) async {
    //print(' FACE SETUP: Picking image for $position');
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      //print(' FACE SETUP: Reading image bytes for $position');
      final bytes = await pickedFile.readAsBytes();

      setState(() {
        switch (position) {
          case 'left':
            _leftImageBytes = bytes;
            _leftImageName = pickedFile.name;
            break;
          case 'right':
            _rightImageBytes = bytes;
            _rightImageName = pickedFile.name;
            break;
          case 'front':
            _frontImageBytes = bytes;
            _frontImageName = pickedFile.name;
            break;
        }
      });
      //print(' FACE SETUP: Image picked for $position (${bytes.length} bytes)');
    } else {
      //print(' FACE SETUP: No image selected for $position');
    }
  }

  Future<String?> _uploadImage(
      Uint8List imageBytes, String position, String fileName) async {
    try {
      //print(' FACE SETUP: Uploading $position image to Firebase Storage...');
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance
          .ref()
          .child('face_images/$userId/$position.jpg');

      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await uploadTask.ref.getDownloadURL();
      //print(' FACE SETUP: $position image uploaded to Firebase. URL: $url');
      return url;
    } catch (e) {
      //print(' FACE SETUP: Error uploading $position image to Firebase: $e');
      return null;
    }
  }

  Future<void> _submitFaceSetup() async {
    //print(' FACE SETUP: Submit button pressed');

    if (_leftImageBytes == null ||
        _rightImageBytes == null ||
        _frontImageBytes == null) {
      //print(' FACE SETUP: Not all images selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all 3 images')),
      );
      return;
    }

    //print(' FACE SETUP: All images selected');
    setState(() {
      _isUploading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        //print(' FACE SETUP: No user logged in!');
        throw Exception('No user logged in');
      }
      //print(' FACE SETUP: User ID = $userId');

      // Step 1: Upload to Firebase Storage
      //print(' FACE SETUP: Starting Firebase Storage uploads...');
      final leftUrl = await _uploadImage(
          _leftImageBytes!, 'left', _leftImageName ?? 'left.jpg');
      final rightUrl = await _uploadImage(
          _rightImageBytes!, 'right', _rightImageName ?? 'right.jpg');
      final frontUrl = await _uploadImage(
          _frontImageBytes!, 'front', _frontImageName ?? 'front.jpg');

      if (leftUrl == null || rightUrl == null || frontUrl == null) {
        throw Exception('Failed to upload one or more images to Firebase');
      }
      //print(' FACE SETUP: All images uploaded to Firebase Storage');

      // Step 2: Register with Face Recognition API using Firebase URLs
      //print(' FACE SETUP: Registering faces with API using Firebase URLs...');

      final registered = await FaceRecognitionAPI.registerFaceFromUrls(
        uid: userId,
        leftUrl: leftUrl,
        rightUrl: rightUrl,
        frontUrl: frontUrl,
      );

      if (!registered) {
        //print(' FACE SETUP: Warning - Failed to register with API');
        // Show warning but continue
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Warning: Face recognition may not work. Check API connection.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        //print(' FACE SETUP: Faces registered with API successfully');
      }

      // Step 3: Update Firestore user document
      //print(' FACE SETUP: Updating Firestore user document...');
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'faceImages': {
          'left': leftUrl,
          'right': rightUrl,
          'front': frontUrl,
        },
        'faceSetupComplete': true,
      }, SetOptions(merge: true));

      //print(' FACE SETUP: Firestore document updated');

      if (mounted) {
        //print(' FACE SETUP: Navigating to setup complete screen...');
        Navigator.pushReplacementNamed(context, '/setup-complete');
        //print(' FACE SETUP: Navigation called');
      }
    } catch (e) {
      //print(' FACE SETUP ERROR: $e');
      //print(' FACE SETUP ERROR TYPE: ${e.runtimeType}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Face Recognition')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Upload 3 photos of yourself',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildImagePicker('Left Side', _leftImageBytes, 'left'),
            const SizedBox(height: 16),
            _buildImagePicker('Right Side', _rightImageBytes, 'right'),
            const SizedBox(height: 16),
            _buildImagePicker('Front View', _frontImageBytes, 'front'),
            const SizedBox(height: 48),
            _isUploading
                ? const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Uploading and registering images...'),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _submitFaceSetup,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Submit and Continue'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(
      String label, Uint8List? imageBytes, String position) {
    return Row(
      children: [
        Expanded(
          child: Text(label),
        ),
        ElevatedButton(
          onPressed: () => _pickImage(position),
          child: Text(imageBytes == null ? 'Upload' : 'Change'),
        ),
        if (imageBytes != null) const Icon(Icons.check, color: Colors.green),
      ],
    );
  }
}
