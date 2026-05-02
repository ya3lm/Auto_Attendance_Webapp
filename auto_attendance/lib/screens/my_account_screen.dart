import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      print(' MY ACCOUNT: Loading user data...');
      final userId = _auth.currentUser?.uid;

      if (userId == null) {
        print(' MY ACCOUNT: No user logged in');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print(' MY ACCOUNT: User ID = $userId');
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        print(' MY ACCOUNT: User document found');
        print(' MY ACCOUNT: Data = ${userDoc.data()}');
        setState(() {
          _userData = userDoc.data();
          _isLoading = false;
        });
      } else {
        print(' MY ACCOUNT: User document does not exist');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print(' MY ACCOUNT ERROR: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading account: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(
      text: _userData?['name']?.toString() ?? '',
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      await _updateName(newName.trim());
    }
  }

  Future<void> _updateName(String newName) async {
    try {
      print(' MY ACCOUNT: Updating name to: $newName');

      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'name': newName,
      });

      print(' MY ACCOUNT: Name updated successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload data
      _loadUserData();
    } catch (e) {
      print(' MY ACCOUNT: Error updating name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentName = _userData?['name']?.toString() ?? 'N/A';
    final isNameMissing = currentName == 'N/A' || currentName.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Name Row with Edit Button
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('Name:', currentName),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editName,
                  tooltip: 'Edit Name',
                ),
              ],
            ),

            // Warning if name is missing
            if (isNameMissing) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please set your name for attendance tracking',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            _buildInfoRow('Email:', _userData?['email']?.toString() ?? 'N/A'),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Account Type:',
              _userData?['isAdmin'] == true ? 'Admin' : 'Student',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Face Setup:',
              _userData?['faceSetupComplete'] == true
                  ? 'Complete'
                  : 'Incomplete',
            ),
            const SizedBox(height: 48),
            const Text(
              'Additional features coming soon!',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
