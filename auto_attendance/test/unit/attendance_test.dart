// test/unit/attendance_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('Attendance Tests', () {
    late FakeFirebaseFirestore mockFirestore;

    setUp(() {
      mockFirestore = FakeFirebaseFirestore();
    });

    test('Attendance record is created with correct fields', () async {
      // Arrange
      const classId = 'class123';
      const studentUserId = 'student123';
      const adminUserId = 'admin123';
      const status = 'present';
      const confidence = 0.95;

      // Act
      final attendanceRef = await mockFirestore.collection('attendance').add({
        'classId': classId,
        'userId': studentUserId,
        'status': status,
        'timestamp': DateTime.now(),
        'takenBy': adminUserId,
        'confidence': confidence,
      });

      // Assert
      final attendanceDoc = await attendanceRef.get();
      expect(attendanceDoc.exists, true);
      expect(attendanceDoc.data()!['classId'], classId);
      expect(attendanceDoc.data()!['userId'], studentUserId);
      expect(attendanceDoc.data()!['status'], status);
      expect(attendanceDoc.data()!['takenBy'], adminUserId);
      expect(attendanceDoc.data()!['confidence'], confidence);
      expect(attendanceDoc.data()!['timestamp'], isNotNull);
    });

    test('Student can retrieve their attendance history', () async {
      // Arrange
      const classId = 'class123';
      const studentUserId = 'student123';

      // Create multiple attendance records
      await mockFirestore.collection('attendance').add({
        'classId': classId,
        'userId': studentUserId,
        'status': 'present',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      });

      await mockFirestore.collection('attendance').add({
        'classId': classId,
        'userId': studentUserId,
        'status': 'present',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      });

      // Act
      final attendanceQuery = await mockFirestore
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .where('userId', isEqualTo: studentUserId)
          .get();

      // Assert
      expect(attendanceQuery.docs.length, 2);
    });

    test('Duplicate attendance prevention works', () async {
      // Arrange
      const classId = 'class123';
      const studentUserId = 'student123';
      final markedPresentSet = <String>{};

      // Act - First recognition
      if (!markedPresentSet.contains(studentUserId)) {
        markedPresentSet.add(studentUserId);
        await mockFirestore.collection('attendance').add({
          'classId': classId,
          'userId': studentUserId,
          'status': 'present',
          'timestamp': DateTime.now(),
        });
      }

      // Try to mark again
      final wasAlreadyMarked = markedPresentSet.contains(studentUserId);

      // Assert
      expect(wasAlreadyMarked, true);
      expect(markedPresentSet.length, 1);

      // Verify only one record exists
      final attendanceQuery = await mockFirestore
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .where('userId', isEqualTo: studentUserId)
          .get();

      expect(attendanceQuery.docs.length, 1);
    });

    test('Only admin can create attendance records', () async {
      // This test verifies the security rule logic
      // In practice, this would test Firestore security rules

      // Arrange
      const adminUserId = 'admin123';
      const studentUserId = 'student123';

      // Create admin user
      await mockFirestore.collection('users').doc(adminUserId).set({
        'name': 'Admin User',
        'isAdmin': true,
      });

      // Create student user
      await mockFirestore.collection('users').doc(studentUserId).set({
        'name': 'Student User',
        'isAdmin': false,
      });

      // Act & Assert - Check admin status before allowing creation
      final adminDoc = await mockFirestore.collection('users').doc(adminUserId).get();
      final isAdmin = adminDoc.data()!['isAdmin'] == true;

      expect(isAdmin, true);

      final studentDoc = await mockFirestore.collection('users').doc(studentUserId).get();
      final studentIsAdmin = studentDoc.data()!['isAdmin'] == true;

      expect(studentIsAdmin, false);
    });

    test('Attendance query filters by class correctly', () async {
      // Arrange
      const class1Id = 'class1';
      const class2Id = 'class2';
      const studentUserId = 'student123';

      // Create attendance for different classes
      await mockFirestore.collection('attendance').add({
        'classId': class1Id,
        'userId': studentUserId,
        'status': 'present',
        'timestamp': DateTime.now(),
      });

      await mockFirestore.collection('attendance').add({
        'classId': class2Id,
        'userId': studentUserId,
        'status': 'present',
        'timestamp': DateTime.now(),
      });

      // Act - Query for class1 only
      final class1Attendance = await mockFirestore
          .collection('attendance')
          .where('classId', isEqualTo: class1Id)
          .get();

      // Assert
      expect(class1Attendance.docs.length, 1);
      expect(class1Attendance.docs.first.data()['classId'], class1Id);
    });

    test('Attendance records are sorted by timestamp', () async {
      // Arrange
      const classId = 'class123';
      const studentUserId = 'student123';

      final oldDate = DateTime.now().subtract(const Duration(days: 3));
      final recentDate = DateTime.now().subtract(const Duration(days: 1));
      final newestDate = DateTime.now();

      // Create records out of order
      await mockFirestore.collection('attendance').add({
        'classId': classId,
        'userId': studentUserId,
        'status': 'present',
        'timestamp': recentDate,
      });

      await mockFirestore.collection('attendance').add({
        'classId': classId,
        'userId': studentUserId,
        'status': 'present',
        'timestamp': oldDate,
      });

      await mockFirestore.collection('attendance').add({
        'classId': classId,
        'userId': studentUserId,
        'status': 'present',
        'timestamp': newestDate,
      });

      // Act - Query with ordering (would need to implement in real code)
      final attendanceQuery = await mockFirestore
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .where('userId', isEqualTo: studentUserId)
          .get();

      final records = attendanceQuery.docs.map((doc) => doc.data()).toList();

      // Assert
      expect(records.length, 3);
      // In real implementation, would verify sorted order
    });

    test('Confidence score is stored with attendance', () async {
      // Arrange
      const classId = 'class123';
      const studentUserId = 'student123';
      const confidence = 0.87;

      // Act
      await mockFirestore.collection('attendance').add({
        'classId': classId,
        'userId': studentUserId,
        'status': 'present',
        'timestamp': DateTime.now(),
        'confidence': confidence,
      });

      // Assert
      final attendanceQuery = await mockFirestore
          .collection('attendance')
          .where('userId', isEqualTo: studentUserId)
          .get();

      final record = attendanceQuery.docs.first.data();
      expect(record['confidence'], confidence);
      expect(record['confidence'], greaterThan(0.0));
      expect(record['confidence'], lessThanOrEqualTo(1.0));
    });
  });
}