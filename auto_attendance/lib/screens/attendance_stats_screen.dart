import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceStatsScreen extends StatefulWidget {
  const AttendanceStatsScreen({super.key});

  @override
  State<AttendanceStatsScreen> createState() => _AttendanceStatsScreenState();
}

class _AttendanceStatsScreenState extends State<AttendanceStatsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _classStats = [];

  @override
  void initState() {
    super.initState();
    _loadAttendanceStats();
  }

  Future<void> _loadAttendanceStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Load user's enrolled classes
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final classIds = List<String>.from(userDoc.data()?['classes'] ?? []);

      if (classIds.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load attendance for each class
      int totalPresent = 0;
      int totalAbsent = 0;
      final classStatsList = <Map<String, dynamic>>[];

      for (final classId in classIds) {
        // Get class name
        final classDoc =
            await _firestore.collection('classes').doc(classId).get();
        final className = classDoc.data()?['name'] ?? 'Unknown Class';

        // Get attendance records for this class
        final attendanceQuery = await _firestore
            .collection('attendance')
            .where('classId', isEqualTo: classId)
            .where('userId', isEqualTo: userId)
            .get();

        int classPresent = 0;
        int classAbsent = 0;
        final records = <Map<String, dynamic>>[];

        for (final doc in attendanceQuery.docs) {
          final data = doc.data();
          final status = data['status'] ?? 'unknown';

          if (status == 'present') {
            classPresent++;
          } else if (status == 'absent') {
            classAbsent++;
          }

          records.add({
            'date': (data['timestamp'] as Timestamp?)?.toDate(),
            'status': status,
          });
        }

        totalPresent += classPresent;
        totalAbsent += classAbsent;

        classStatsList.add({
          'classId': classId,
          'className': className,
          'present': classPresent,
          'absent': classAbsent,
          'total': classPresent + classAbsent,
          'percentage': (classPresent + classAbsent) > 0
              ? (classPresent / (classPresent + classAbsent) * 100)
              : 0.0,
          'records': records,
        });
      }

      setState(() {
        _stats = {
          'totalPresent': totalPresent,
          'totalAbsent': totalAbsent,
          'totalSessions': totalPresent + totalAbsent,
          'overallPercentage': (totalPresent + totalAbsent) > 0
              ? (totalPresent / (totalPresent + totalAbsent) * 100)
              : 0.0,
        };
        _classStats = classStatsList;
        _isLoading = false;
      });
    } catch (e) {
      //print('Error loading attendance stats: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: ${e.toString()}')),
        );
      }
    }
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance Stats')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_classStats.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance Stats')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 100, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No attendance records yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Attend a class to see your stats here!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendanceStats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAttendanceStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Stats Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Attendance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Percentage Circle
                      Center(
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: _stats['overallPercentage'] / 100,
                                strokeWidth: 12,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getPercentageColor(
                                      _stats['overallPercentage']),
                                ),
                              ),
                              Center(
                                child: Text(
                                  '${_stats['overallPercentage'].toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Present',
                            '${_stats['totalPresent']}',
                            Colors.green,
                            Icons.check_circle,
                          ),
                          _buildStatItem(
                            'Absent',
                            '${_stats['totalAbsent']}',
                            Colors.red,
                            Icons.cancel,
                          ),
                          _buildStatItem(
                            'Total',
                            '${_stats['totalSessions']}',
                            Colors.blue,
                            Icons.calendar_today,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Per-Class Stats
              const Text(
                'By Class',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _classStats.length,
                itemBuilder: (context, index) {
                  final classStat = _classStats[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _getPercentageColor(classStat['percentage']),
                        child: Text(
                          '${classStat['percentage'].toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        classStat['className'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${classStat['present']} present • ${classStat['absent']} absent',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.green),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${classStat['present']}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text('Present'),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Icon(Icons.cancel,
                                          color: Colors.red),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${classStat['absent']}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text('Absent'),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Icon(Icons.analytics,
                                          color: Colors.blue),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${classStat['total']}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text('Total'),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
