import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/setup_face_screen.dart';
import 'screens/setup_complete_screen.dart';
import 'screens/students_list_screen.dart';
import 'screens/student_detail_screen.dart';
import 'screens/my_account_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/create_class_screen.dart';
import 'screens/join_class_screen.dart';
import 'screens/attendance_stats_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/terms': (context) => TermsScreen(),
        '/setup-face': (context) => SetupFaceScreen(),
        '/setup-complete': (context) => SetupCompleteScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/admin': (context) => AdminScreen(),
        '/create-class': (context) => CreateClassScreen(),
        '/students-list': (context) => StudentsListScreen(),
        '/student-detail': (context) => StudentDetailScreen(),
        '/join-class': (context) => JoinClassScreen(),
        '/my-account': (context) => MyAccountScreen(),
        '/attendance-stats': (context) => AttendanceStatsScreen(),
      },
    );
  }
}
