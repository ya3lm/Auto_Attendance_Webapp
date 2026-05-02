import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'dart:async';
//ignore_for_file: avoid_print
import 'dart:typed_data';
//rest of imports
import '../services/face_recognition_api.dart';

class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  final _firestore = FirebaseFirestore.instance;

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isRecognitionActive = false;
  Timer? _recognitionTimer;

  final Set<String> _markedPresentUserIds = {};
  final List<Map<String, dynamic>> _recognizedStudents = [];

  static const int recognitionIntervalSeconds = 2;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      print(' CAMERA: Initializing...');

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        print(' CAMERA: No cameras found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No camera available on this device')),
          );
        }
        return;
      }

      final camera = cameras.first;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      setState(() {
        _isCameraInitialized = true;
      });

      print('CAMERA: Initialized successfully');
    } catch (e) {
      print(' CAMERA ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: ${e.toString()}')),
        );
      }
    }
  }

  void _startRecognition(String classId) {
    if (!_isCameraInitialized || _cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not ready')),
      );
      return;
    }

    setState(() {
      _isRecognitionActive = true;
    });

    print(' ATTENDANCE: Starting continuous recognition...');
    print(' ATTENDANCE: Class ID = $classId');

    _recognitionTimer = Timer.periodic(
      const Duration(seconds: recognitionIntervalSeconds),
      (timer) => _recognizeFace(classId),
    );
  }

  void _stopRecognition() {
    _recognitionTimer?.cancel();
    _recognitionTimer = null;

    setState(() {
      _isRecognitionActive = false;
    });

    print(' ATTENDANCE: Stopped continuous recognition');
  }

  /// Find user ID by searching for name in Firestore
  Future<String?> _findUserIdByName(String name) async {
    try {
      print(' SEARCH: Looking for user with name: $name');

      final querySnapshot = await _firestore
          .collection('users')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      print(' SEARCH: Query returned ${querySnapshot.docs.length} results');

      if (querySnapshot.docs.isNotEmpty) {
        final userId = querySnapshot.docs.first.id;
        final userData = querySnapshot.docs.first.data();
        print(' SEARCH: Found user ID: $userId for name: $name');
        print(' SEARCH: User data: $userData');
        return userId;
      } else {
        print(' SEARCH: No user found with name: $name');
        return null;
      }
    } catch (e) {
      print(' SEARCH ERROR: $e');
      return null;
    }
  }

  Future<void> _recognizeFace(String classId) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print(' ATTENDANCE: Camera not initialized, skipping frame');
      return;
    }

    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print(' ATTENDANCE: Capturing frame for recognition...');

      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      print(' ATTENDANCE: Frame captured (${bytes.length} bytes)');
      print(' ATTENDANCE: Sending frame to API...');

      final recognizedId = await FaceRecognitionAPI.recognizeFace(bytes);

      print(' ATTENDANCE: API Response - Recognized ID: $recognizedId');

      if (recognizedId != null) {
        print(' ATTENDANCE: Face recognized! ID from API: "$recognizedId"');

        // Try to find user by ID first
        print(' ATTENDANCE: Step 1 - Looking up user by ID: $recognizedId');
        var userDoc =
            await _firestore.collection('users').doc(recognizedId).get();

        print(' ATTENDANCE: User doc exists by ID: ${userDoc.exists}');

        String? actualUserId = recognizedId;

        // If user doesn't exist with that ID, try searching by name
        if (!userDoc.exists) {
          print(' ATTENDANCE: No user found with ID "$recognizedId"');
          print(' ATTENDANCE: Step 2 - Searching Firestore by name...');

          actualUserId = await _findUserIdByName(recognizedId);

          if (actualUserId == null) {
            print(
                ' ATTENDANCE: FAILED - Could not find user by ID or name: $recognizedId');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Face recognized as "$recognizedId" but not found in database'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            return;
          }

          print(' ATTENDANCE: Found actual user ID: $actualUserId');

          // Fetch the actual user document
          print(
              ' ATTENDANCE: Step 3 - Fetching user document for: $actualUserId');
          userDoc =
              await _firestore.collection('users').doc(actualUserId).get();
          print(' ATTENDANCE: User doc exists: ${userDoc.exists}');
        }

        // Check if already marked
        print(' ATTENDANCE: Step 4 - Checking if already marked present...');
        print(
            ' ATTENDANCE: Currently marked: ${_markedPresentUserIds.toList()}');
        print(' ATTENDANCE: Checking for: $actualUserId');

        if (_markedPresentUserIds.contains(actualUserId)) {
          print(
              ' ATTENDANCE: User $actualUserId already marked present - SKIPPING');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          return;
        }

        print(' ATTENDANCE: User NOT yet marked - proceeding...');

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final studentName = userData['name'] ?? 'Unknown';

          print(' ATTENDANCE: Step 5 - User details:');
          print('   - User ID: $actualUserId');
          print('   - Name: $studentName');
          print('   - Full data: $userData');

          print(' ATTENDANCE: Step 6 - Adding to marked present set...');
          _markedPresentUserIds.add(actualUserId);
          print(
              ' ATTENDANCE: Added to set. Set now contains: ${_markedPresentUserIds.toList()}');

          // Save attendance
          print(' ATTENDANCE: Step 7 - Saving to Firestore...');
          try {
            await _firestore.collection('attendance').add({
              'classId': classId,
              'userId': actualUserId,
              'status': 'present',
              'timestamp': FieldValue.serverTimestamp(),
              'takenBy': FirebaseAuth.instance.currentUser!.uid,
              'confidence': 0.95,
            });
            print(' ATTENDANCE: Saved to Firestore successfully');
          } catch (e) {
            print(' ATTENDANCE: Error saving to Firestore: $e');
          }

          print(' ATTENDANCE: Step 8 - Updating UI...');
          setState(() {
            _recognizedStudents.add({
              'userId': actualUserId,
              'name': studentName,
              'timestamp': DateTime.now(),
            });
          });
          print(
              ' ATTENDANCE: UI updated. Total students: ${_recognizedStudents.length}');

          print('🎉 ATTENDANCE: SUCCESS - $studentName marked present!');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ $studentName marked present'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          print(
              ' ATTENDANCE: User document does not exist for ID: $actualUserId');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }
      } else {
        print(' ATTENDANCE: No face recognized in current frame');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
    } catch (e, stackTrace) {
      print(' ATTENDANCE ERROR: $e');
      print('Stack trace: $stackTrace');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  Future<void> _finishAttendance() async {
    _stopRecognition();

    print(' ATTENDANCE: Finishing attendance session');
    print(' ATTENDANCE: Total students marked: ${_recognizedStudents.length}');
    print(' ATTENDANCE: Student list: $_recognizedStudents');

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Attendance Complete'),
          content: Text(
            '${_recognizedStudents.length} student(s) marked present',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _recognitionTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Take Attendance')),
        body: const Center(child: Text('Error: No class data')),
      );
    }

    final className = args['className'] as String;
    final classId = args['classId'] as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('Take Attendance - $className'),
        actions: [
          if (_isRecognitionActive)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _finishAttendance,
              tooltip: 'Finish',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: _isCameraInitialized
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_cameraController!),
                        if (_isRecognitionActive)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fiber_manual_record,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'RECOGNIZING',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isRecognitionActive)
                  ElevatedButton.icon(
                    onPressed: () => _startRecognition(classId),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Taking Attendance'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _finishAttendance,
                    icon: const Icon(Icons.stop),
                    label: const Text('Finish Taking Attendance'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Students Present:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_recognizedStudents.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _recognizedStudents.isEmpty
                ? Center(
                    child: Text(
                      _isRecognitionActive
                          ? 'Waiting for students...'
                          : 'Press start to begin',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _recognizedStudents.length,
                    itemBuilder: (context, index) {
                      final student = _recognizedStudents[index];
                      final timestamp = student['timestamp'] as DateTime;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            student['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                          ),
                          trailing: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
