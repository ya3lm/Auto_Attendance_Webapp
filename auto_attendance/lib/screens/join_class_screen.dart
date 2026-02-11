import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _classCodeController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  bool _isJoining = false;

  Future<void> _joinClass() async {
    if (_classCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a class code')),
      );
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      final classCode = _classCodeController.text.trim();
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Find class with the code
      final classQuery = await _firestore
          .collection('classes')
          .where('code', isEqualTo: classCode)
          .get();

      if (classQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Class not found. Check the code and try again.')),
          );
        }
        return;
      }

      final classDoc = classQuery.docs.first;
      final classId = classDoc.id;
      final className = classDoc.data()['name'];

      // Check if already enrolled
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userClasses = List<String>.from(userDoc.data()?['classes'] ?? []);

      if (userClasses.contains(classId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You are already enrolled in this class')),
          );
        }
        return;
      }

      // Add student to class
      await _firestore.collection('classes').doc(classId).update({
        'students': FieldValue.arrayUnion([userId]),
      });

      // Add class to user
      await _firestore.collection('users').doc(userId).update({
        'classes': FieldValue.arrayUnion([classId]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully joined $className')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining class: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Class')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter Class Code',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _classCodeController,
              decoration: const InputDecoration(
                labelText: '5-Digit Class Code',
                hintText: '12345',
              ),
              keyboardType: TextInputType.number,
              maxLength: 5,
            ),
            const SizedBox(height: 32),
            _isJoining
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _joinClass,
                    child: const Text('Join Class'),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _classCodeController.dispose();
    super.dispose();
  }
}
