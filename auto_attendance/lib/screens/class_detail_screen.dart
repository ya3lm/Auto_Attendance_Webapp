import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({super.key});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // We'll load attendance records when the widget builds
    // because we need the arguments from the route
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _isLoading) {
      _loadAttendanceRecords(args['classId']);
    }
  }

  Future<void> _loadAttendanceRecords(String classId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Load attendance records for this user in this class
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> records = [];
      for (var doc in attendanceQuery.docs) {
        final data = doc.data();
        records.add({
          'date': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'status': data['status'] ?? 'present',
        });
      }

      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      //print('Error loading attendance: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _takeAttendance(String classId, String className) {
    Navigator.pushNamed(
      context,
      '/take-attendance',
      arguments: {
        'classId': classId,
        'className': className,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Class Details')),
        body: const Center(child: Text('Error: No class data')),
      );
    }

    final className = args['className'] as String;
    final classId = args['classId'] as String;
    final isAdmin = args['isAdmin'] as bool;

    return Scaffold(
      appBar: AppBar(title: Text(className)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Class Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      className,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Class ID: $classId',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Button (different for admin vs student)
            if (isAdmin)
              ElevatedButton.icon(
                onPressed: () => _takeAttendance(classId, className),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Attendance'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  // Student view attendance - could expand this later
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your attendance records are shown below'),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('My Attendance'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),

            const SizedBox(height: 24),

            // Attendance Records Section
            const Text(
              'Attendance History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Attendance List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _attendanceRecords.isEmpty
                      ? const Center(
                          child: Text(
                            'No attendance records yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _attendanceRecords.length,
                          itemBuilder: (context, index) {
                            final record = _attendanceRecords[index];
                            final date = record['date'] as DateTime;
                            final status = record['status'] as String;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  status == 'present'
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: status == 'present'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                title: Text(
                                  '${date.month}/${date.day}/${date.year}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                ),
                                trailing: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: status == 'present'
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
