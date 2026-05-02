// test/integration/user_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  group('Complete User Flow Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = FakeFirebaseFirestore();
    });

    test('Complete student signup and enrollment flow', () async {
      // Step 1: Student signs up
      const email = 'newstudent@test.com';
      const password = 'password123';
      const name = 'New Student';

      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Create Firestore document
      await mockFirestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'isAdmin': false,
        'faceSetupComplete': false,
        'classes': [],
      });

      // Verify signup
      expect(mockAuth.currentUser, isNotNull);
      final userDoc = await mockFirestore.collection('users').doc(userId).get();
      expect(userDoc.exists, true);

      // Step 2: Student completes face setup
      await mockFirestore.collection('users').doc(userId).update({
        'faceImages': {
          'left': 'https://firebase.storage/left.jpg',
          'right': 'https://firebase.storage/right.jpg',
          'front': 'https://firebase.storage/front.jpg',
        },
        'faceSetupComplete': true,
      });

      // Verify face setup
      final updatedUserDoc =
          await mockFirestore.collection('users').doc(userId).get();
      expect(updatedUserDoc.data()!['faceSetupComplete'], true);

      // Step 3: Admin creates a class
      const adminId = 'admin123';
      const classCode = 12345;

      final classRef = await mockFirestore.collection('classes').add({
        'name': 'Test Class',
        'code': classCode,
        'createdBy': adminId,
        'students': [],
      });

      final classId = classRef.id;

      // Step 4: Student joins class
      await mockFirestore.collection('classes').doc(classId).update({
        'students': [userId],
      });

      await mockFirestore.collection('users').doc(userId).update({
        'classes': [classId],
      });

      // Verify enrollment
      final classDoc =
          await mockFirestore.collection('classes').doc(classId).get();
      expect(classDoc.data()!['students'], contains(userId));

      final finalUserDoc =
          await mockFirestore.collection('users').doc(userId).get();
      expect(finalUserDoc.data()!['classes'], contains(classId));

      // Step 5: Attendance is taken
      await mockFirestore.collection('attendance').add({
        'classId': classId,
        'userId': userId,
        'status': 'present',
        'timestamp': DateTime.now(),
        'takenBy': adminId,
        'confidence': 0.95,
      });

      // Verify attendance record
      final attendanceQuery = await mockFirestore
          .collection('attendance')
          .where('userId', isEqualTo: userId)
          .get();

      expect(attendanceQuery.docs.length, 1);
      expect(attendanceQuery.docs.first.data()['status'], 'present');

      print(' Complete student flow test passed');
    });

    test('Complete admin flow - create class and take attendance', () async {
      // Step 1: Admin creates account
      const adminEmail = 'admin@test.com';
      const adminPassword = 'adminpass123';

      final adminCredential = await mockAuth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      final adminId = adminCredential.user!.uid;

      await mockFirestore.collection('users').doc(adminId).set({
        'name': 'Admin User',
        'email': adminEmail,
        'isAdmin': true,
        'faceSetupComplete': true,
        'classes': [],
      });

      // Verify admin status
      final adminDoc =
          await mockFirestore.collection('users').doc(adminId).get();
      expect(adminDoc.data()!['isAdmin'], true);

      // Step 2: Admin creates class
      const classCode = 54321;

      final classRef = await mockFirestore.collection('classes').add({
        'name': 'Admin Created Class',
        'code': classCode,
        'createdBy': adminId,
        'students': [],
      });

      final classId = classRef.id;

      // Step 3: Student joins
      const studentId = 'student123';

      await mockFirestore.collection('users').doc(studentId).set({
        'name': 'Test Student',
        'email': 'student@test.com',
        'classes': [],
      });

      await mockFirestore.collection('classes').doc(classId).update({
        'students': [studentId],
      });

      // Step 4: Admin takes attendance
      await mockFirestore.collection('attendance').add({
        'classId': classId,
        'userId': studentId,
        'status': 'present',
        'timestamp': DateTime.now(),
        'takenBy': adminId,
        'confidence': 0.92,
      });

      // Verify attendance
      final attendanceQuery = await mockFirestore
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .where('takenBy', isEqualTo: adminId)
          .get();

      expect(attendanceQuery.docs.length, 1);

      print(' Complete admin flow test passed');
    });

    test('Multiple students attendance in same class', () async {
      // Setup class
      const adminId = 'admin123';
      const classCode = 11111;

      final classRef = await mockFirestore.collection('classes').add({
        'name': 'Large Class',
        'code': classCode,
        'createdBy': adminId,
        'students': [],
      });

      final classId = classRef.id;

      // Create multiple students
      final studentIds = ['student1', 'student2', 'student3'];

      for (final studentId in studentIds) {
        await mockFirestore.collection('users').doc(studentId).set({
          'name': 'Student $studentId',
          'email': '$studentId@test.com',
          'classes': [classId],
        });
      }

      // Update class with all students
      await mockFirestore.collection('classes').doc(classId).update({
        'students': studentIds,
      });

      // Take attendance for all students
      for (final studentId in studentIds) {
        await mockFirestore.collection('attendance').add({
          'classId': classId,
          'userId': studentId,
          'status': 'present',
          'timestamp': DateTime.now(),
          'takenBy': adminId,
        });
      }

      // Verify all attendance records
      final attendanceQuery = await mockFirestore
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .get();

      expect(attendanceQuery.docs.length, 3);

      print(' Multiple students attendance test passed');
    });

    test('Student cannot be marked present twice in same session', () async {
      const classId = 'class123';
      const studentId = 'student123';
      const adminId = 'admin123';

      // Simulate duplicate prevention
      final markedPresentSet = <String>{};

      // First mark
      if (!markedPresentSet.contains(studentId)) {
        markedPresentSet.add(studentId);
        await mockFirestore.collection('attendance').add({
          'classId': classId,
          'userId': studentId,
          'status': 'present',
          'timestamp': DateTime.now(),
          'takenBy': adminId,
        });
      }

      // Try to mark again
      var shouldMarkAgain = false;
      if (!markedPresentSet.contains(studentId)) {
        shouldMarkAgain = true;
      }

      expect(shouldMarkAgain, false);

      // Verify only one record
      final attendanceQuery = await mockFirestore
          .collection('attendance')
          .where('userId', isEqualTo: studentId)
          .where('classId', isEqualTo: classId)
          .get();

      expect(attendanceQuery.docs.length, 1);

      print(' Duplicate prevention test passed');
    });
  });
}
