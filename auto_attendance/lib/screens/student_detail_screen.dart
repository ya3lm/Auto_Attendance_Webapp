import 'package:flutter/material.dart';

class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final studentData = args['studentData'] as Map<String, dynamic>;
    final studentId = args['studentId'] as String;

    return Scaffold(
      appBar: AppBar(title: const Text('Student Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Student ID:', studentId),
            const SizedBox(height: 16),
            _buildDetailRow('Name:', studentData['name'] ?? 'N/A'),
            const SizedBox(height: 16),
            _buildDetailRow('Email:', studentData['email'] ?? 'N/A'),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Face Setup Complete:',
              studentData['faceSetupComplete'] == true ? 'Yes' : 'No',
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Classes Enrolled:',
              (studentData['classes'] as List?)?.length.toString() ?? '0',
            ),
            const SizedBox(height: 32),
            const Text(
              'Enrolled Classes:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: (studentData['classes'] as List?)?.isEmpty ?? true
                  ? const Text('No classes enrolled')
                  : ListView.builder(
                      itemCount: (studentData['classes'] as List).length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            title: Text(studentData['classes'][index]),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
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
