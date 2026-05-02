import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _showSettings = false;
  String _userName = '';
  bool _isAdmin = false;
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _auth.currentUser!.uid;
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data()!;

      setState(() {
        _userName = userData['name'] ?? '';
        _isAdmin = userData['isAdmin'] ?? false;
      });

      final classIds = List<String>.from(userData['classes'] ?? []);

      if (classIds.isNotEmpty) {
        await _loadClassNames(classIds);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      //print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadClassNames(List<String> classIds) async {
    try {
      List<Map<String, dynamic>> loadedClasses = [];

      for (String classId in classIds) {
        final classDoc =
            await _firestore.collection('classes').doc(classId).get();
        if (classDoc.exists) {
          loadedClasses.add({
            'id': classId,
            'name': classDoc.data()?['name'] ?? 'Unknown Class',
            'code': classDoc.data()?['code'] ?? '',
          });
        }
      }

      setState(() {
        _classes = loadedClasses;
        _isLoading = false;
      });
    } catch (e) {
      //print('Error loading class names: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _openClass(Map<String, dynamic> classData) async {
    await Navigator.pushNamed(
      context,
      '/class-detail',
      arguments: {
        'classId': classData['id'],
        'className': classData['name'],
        'isAdmin': _isAdmin,
      },
    );
    _loadUserData(); // Refresh data when returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome $_userName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Your Classes:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _classes.isEmpty
                          ? const Center(
                              child: Text(
                                  'No classes yet. Join a class to get started!'),
                            )
                          : ListView.builder(
                              itemCount: _classes.length,
                              itemBuilder: (context, index) {
                                final classData = _classes[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(
                                      classData['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                        'Class Code: ${classData['code']}'),
                                    trailing:
                                        const Icon(Icons.arrow_forward_ios),
                                    onTap: () => _openClass(classData),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          if (_showSettings)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isAdmin)
                      _buildMenuItem(
                        'Admin',
                        Icons.admin_panel_settings,
                        () => Navigator.pushNamed(context, '/admin'),
                      ),
                    _buildMenuItem(
                      'My Account',
                      Icons.person,
                      () => Navigator.pushNamed(context, '/my-account'),
                    ),
                    _buildMenuItem(
                      'Attendance Stats',
                      Icons.bar_chart,
                      () => Navigator.pushNamed(context, '/attendance-stats'),
                    ),
                    _buildMenuItem(
                      'Join Class',
                      Icons.class_,
                      () async {
                        await Navigator.pushNamed(context, '/join-class');
                        //reload classes after returning
                        _loadUserData();
                      },
                    ),
                    _buildMenuItem(
                      'Sign Out',
                      Icons.logout,
                      _signOut,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        setState(() {
          _showSettings = false;
        });
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Text(text),
          ],
        ),
      ),
    );
  }
}
