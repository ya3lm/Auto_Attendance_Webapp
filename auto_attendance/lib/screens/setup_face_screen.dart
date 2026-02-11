import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class SetupFaceScreen extends StatefulWidget {
  const SetupFaceScreen({super.key});

  @override
  State<SetupFaceScreen> createState() => _SetupFaceScreenState();
}

class _SetupFaceScreenState extends State<SetupFaceScreen> {
  File? _leftImage;
  File? _rightImage;
  File? _frontImage;
  final _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage(String position) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        switch (position) {
          case 'left':
            _leftImage = File(pickedFile.path);
            break;
          case 'right':
            _rightImage = File(pickedFile.path);
            break;
          case 'front':
            _frontImage = File(pickedFile.path);
            break;
        }
      });
    }
  }

  Future<String?> _uploadImage(File image, String position) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance
          .ref()
          .child('face_images/$userId/$position.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitFaceSetup() async {
    if (_leftImage == null || _rightImage == null || _frontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all 3 images')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload images to Firebase Storage
      final leftUrl = await _uploadImage(_leftImage!, 'left');
      final rightUrl = await _uploadImage(_rightImage!, 'right');
      final frontUrl = await _uploadImage(_frontImage!, 'front');

      // Update user document with image URLs
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'faceImages': {
          'left': leftUrl,
          'right': rightUrl,
          'front': frontUrl,
        },
        'faceSetupComplete': true,
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/setup-complete');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
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
            _buildImagePicker('Left Side', _leftImage, 'left'),
            const SizedBox(height: 16),
            _buildImagePicker('Right Side', _rightImage, 'right'),
            const SizedBox(height: 16),
            _buildImagePicker('Front View', _frontImage, 'front'),
            const SizedBox(height: 48),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitFaceSetup,
                    child: const Text('Submit and Continue'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, File? image, String position) {
    return Row(
      children: [
        Expanded(
          child: Text(label),
        ),
        ElevatedButton(
          onPressed: () => _pickImage(position),
          child: Text(image == null ? 'Upload' : 'Change'),
        ),
        if (image != null) const Icon(Icons.check, color: Colors.green),
      ],
    );
  }
}
