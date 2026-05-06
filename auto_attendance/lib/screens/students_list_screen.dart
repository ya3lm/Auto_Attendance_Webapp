import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/face_recognition_api.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: _isProcessing ? null : _showBulkReregisterDialog,
            tooltip: 'Bulk Re-register',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('isAdmin', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading students'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!.docs;

          if (students.isEmpty) {
            return const Center(child: Text('No students found'));
          }

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index].data() as Map<String, dynamic>;
              final studentId = students[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(student['name'] ?? 'Unknown'),
                  subtitle: Text(student['email'] ?? ''),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/student-detail',
                      arguments: {
                        'studentId': studentId,
                        'studentData': student,
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showBulkReregisterDialog() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Re-register Students'),
        content: const Text(
          'Choose an option:\n\n'
          '• New Only: Register only students not yet on server\n'
          '• Force All: Re-register everyone (slower)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'new_only'),
            child: const Text('New Only'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'force_all'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Force All'),
          ),
        ],
      ),
    );

    if (choice == 'new_only') {
      await _bulkReregister(skipExisting: true);
    } else if (choice == 'force_all') {
      await _bulkReregister(skipExisting: false);
    }
  }

  Future<void> _bulkReregister({required bool skipExisting}) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Step 1: Get who's already registered (if skipping)
      Set<String> alreadyRegistered = {};

      if (skipExisting) {
        //print(' Checking who is already registered...');
        final registeredData = await FaceRecognitionAPI.getRegisteredUsers();

        if (registeredData != null && registeredData['users'] != null) {
          alreadyRegistered =
              (registeredData['users'] as Map).keys.toSet().cast<String>();
          //print(' Found ${alreadyRegistered.length} already registered');
        }
      }

      // Step 2: Get all students from Firestore
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isAdmin', isEqualTo: false)
          .where('faceSetupComplete', isEqualTo: true)
          .get();

      //print(' Found ${studentsSnapshot.docs.length} students with face setup');

      // Step 3: Track results
      int success = 0;
      int failed = 0;
      int skipped = 0;

      // Step 4: Loop through each student
      for (final doc in studentsSnapshot.docs) {
        try {
          final userId = doc.id;
          final data = doc.data();
          final studentName = data['name'] ?? 'Unknown';

          // Skip if already registered
          if (skipExisting && alreadyRegistered.contains(userId)) {
            //print(' Skipping $studentName (already registered)');
            skipped++;
            continue;
          }

          // Get face image URLs
          final faceImages = data['faceImages'] as Map<String, dynamic>?;

          if (faceImages == null) {
            //print(' $studentName has no face images');
            failed++;
            continue;
          }

          // Register with API
          //print(' Registering $studentName...');

          final result = await FaceRecognitionAPI.registerFaceFromUrls(
            uid: userId,
            leftUrl: faceImages['left'] as String,
            rightUrl: faceImages['right'] as String,
            frontUrl: faceImages['front'] as String,
          );

          if (result) {
            //print(' $studentName registered');
            success++;
          } else {
            //print(' $studentName failed');
            failed++;
          }
        } catch (e) {
          //print(' Error: $e');
          failed++;
        }
      }

      // Step 5: Show results
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bulk Registration Complete:\n'
              ' Registered: $success\n'
              ' Skipped: $skipped\n'
              ' Failed: $failed',
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: failed > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      //print(' Bulk registration error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
