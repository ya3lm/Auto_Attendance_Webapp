import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _classNameController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  String? _generatedCode;
  bool _isCreating = false;

  String _generateClassCode() {
    final random = Random();
    return (10000 + random.nextInt(90000)).toString();
  }

  Future<void> _createClass() async {
    if (_classNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a class name')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final classCode = _generateClassCode();
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Create class document
      await _firestore.collection('classes').add({
        'name': _classNameController.text.trim(),
        'code': classCode,
        'createdBy': userId,
        'students': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _generatedCode = classCode;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Class created with code: $classCode')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating class: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Class')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _classNameController,
              decoration: const InputDecoration(
                labelText: 'Class Name',
                hintText: 'e.g., Computer Science 101',
              ),
            ),
            const SizedBox(height: 32),
            _isCreating
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createClass,
                    child: const Text('Generate Class Code'),
                  ),
            if (_generatedCode != null) ...[
              const SizedBox(height: 32),
              const Text(
                'Class Code:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _generatedCode!,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share this code with students to join the class',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }
}
