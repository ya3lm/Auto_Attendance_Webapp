import 'package:flutter/material.dart';

class AttendanceStatsScreen extends StatelessWidget {
  const AttendanceStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Stats')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 100,
                color: Colors.grey,
              ),
              SizedBox(height: 32),
              Text(
                'Attendance Stats',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'This feature will display your attendance statistics for all your classes.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Coming soon!',
                style:
                    TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
