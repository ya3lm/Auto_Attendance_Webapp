import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
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
import 'screens/class_detail_screen.dart';
import 'screens/take_attendance_screen.dart';

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
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/terms': (context) => const TermsScreen(),
        '/setup-face': (context) => const SetupFaceScreen(),
        '/setup-complete': (context) => const SetupCompleteScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/admin': (context) => const AdminScreen(),
        '/create-class': (context) => const CreateClassScreen(),
        '/students-list': (context) => const StudentsListScreen(),
        '/student-detail': (context) => const StudentDetailScreen(),
        '/join-class': (context) => const JoinClassScreen(),
        '/my-account': (context) => const MyAccountScreen(),
        '/attendance-stats': (context) => const AttendanceStatsScreen(),
        '/class-detail': (context) => const ClassDetailScreen(),
        '/take-attendance': (context) => const TakeAttendanceScreen(),
      },
    );
  }
}

// This widget checks if user is logged in and where to send them
class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Not logged in
        if (snapshot.data == null) {
          return const LoginScreen();
        }

        // Logged in - check if they completed setup
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
              // User document doesn't exist (shouldn't happen, but just in case)
              return const LoginScreen();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final faceSetupComplete = userData['faceSetupComplete'] ?? false;

            // If face setup not complete, send to setup flow
            if (!faceSetupComplete) {
              // Check if they just signed up (would have accepted terms)
              // For now, always send to terms if face not setup
              return const TermsScreen();
            }

            // Face setup complete, go to dashboard
            return const DashboardScreen();
          },
        );
      },
    );
  }
}
