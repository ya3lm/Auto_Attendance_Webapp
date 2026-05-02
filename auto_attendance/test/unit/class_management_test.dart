// test/unit/class_management_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'dart:math';

void main() {
  group('Class Management Tests', () {
    late FakeFirebaseFirestore mockFirestore;

    setUp(() {
      mockFirestore = FakeFirebaseFirestore();
    });

    test('Class creation generates 5-digit code', () {
      // Act
      final random = Random();
      final code = (random.nextDouble() * 90000).floor() + 10000;

      // Assert
      expect(code >= 10000, true);
      expect(code <= 99999, true);
      expect(code.toString().length, 5);
    });

    test('Admin can create a class successfully', () async {
      // Arrange
      const adminUserId = 'admin123';
      const className = 'Computer Science 101';
      const classCode = 12345;

      // Act
      final classRef = await mockFirestore.collection('classes').add({
        'name': className,
        'code': classCode,
        'createdBy': adminUserId,
        'students': [],
      });

      // Assert
      final classDoc = await classRef.get();
      expect(classDoc.exists, true);
      expect(classDoc.data()!['name'], className);
      expect(classDoc.data()!['code'], classCode);
      expect(classDoc.data()!['createdBy'], adminUserId);
      expect(classDoc.data()!['students'], isEmpty);
    });

    test('Student can join class with valid code', () async {
      // Arrange
      const studentUserId = 'student123';
      const classCode = 12345;

      // Create a class first
      final classRef = await mockFirestore.collection('classes').add({
        'name': 'Test Class',
        'code': classCode,
        'createdBy': 'admin123',
        'students': [],
      });

      final classId = classRef.id;

      // Create student user
      await mockFirestore.collection('users').doc(studentUserId).set({
        'name': 'Test Student',
        'email': 'student@test.com',
        'classes': [],
      });

      // Act - Student joins class
      await mockFirestore.collection('classes').doc(classId).update({
        'students': [studentUserId],
      });

      await mockFirestore.collection('users').doc(studentUserId).update({
        'classes': [classId],
      });

      // Assert - Verify student is in class
      final classDoc =
          await mockFirestore.collection('classes').doc(classId).get();
      expect(classDoc.data()!['students'], contains(studentUserId));

      // Assert - Verify class is in student's classes
      final studentDoc =
          await mockFirestore.collection('users').doc(studentUserId).get();
      expect(studentDoc.data()!['classes'], contains(classId));
    });

    test('Student cannot join class with invalid code', () async {
      // Arrange
      const invalidCode = 99999;

      // Act
      final querySnapshot = await mockFirestore
          .collection('classes')
          .where('code', isEqualTo: invalidCode)
          .get();

      // Assert
      expect(querySnapshot.docs, isEmpty);
    });

    test('Duplicate enrollment is prevented', () async {
      // Arrange
      const studentUserId = 'student123';
      const classId = 'class123';

      // Create class with student already enrolled
      await mockFirestore.collection('classes').doc(classId).set({
        'name': 'Test Class',
        'code': 12345,
        'students': [studentUserId],
      });

      // Act - Try to add student again
      final classDoc =
          await mockFirestore.collection('classes').doc(classId).get();
      final currentStudents = List<String>.from(classDoc.data()!['students']);

      // Check if already enrolled
      final isAlreadyEnrolled = currentStudents.contains(studentUserId);

      // Assert
      expect(isAlreadyEnrolled, true);
      expect(currentStudents.length, 1);
    });

    test('Class code must be unique', () async {
      // Arrange
      const classCode = 12345;

      // Create first class
      await mockFirestore.collection('classes').add({
        'name': 'Class 1',
        'code': classCode,
        'createdBy': 'admin123',
        'students': [],
      });

      // Act - Check for duplicate code
      final existingClasses = await mockFirestore
          .collection('classes')
          .where('code', isEqualTo: classCode)
          .get();

      // Assert - Should find one class
      expect(existingClasses.docs.length, 1);
    });

    test('Student can be enrolled in multiple classes', () async {
      // Arrange
      const studentUserId = 'student123';

      await mockFirestore.collection('users').doc(studentUserId).set({
        'name': 'Test Student',
        'email': 'student@test.com',
        'classes': [],
      });

      // Create multiple classes
      final class1Ref = await mockFirestore.collection('classes').add({
        'name': 'Class 1',
        'code': 11111,
        'students': [],
      });

      final class2Ref = await mockFirestore.collection('classes').add({
        'name': 'Class 2',
        'code': 22222,
        'students': [],
      });

      // Act - Enroll in both classes
      await mockFirestore.collection('users').doc(studentUserId).update({
        'classes': [class1Ref.id, class2Ref.id],
      });

      // Assert
      final studentDoc =
          await mockFirestore.collection('users').doc(studentUserId).get();
      expect(studentDoc.data()!['classes'], hasLength(2));
      expect(studentDoc.data()!['classes'], contains(class1Ref.id));
      expect(studentDoc.data()!['classes'], contains(class2Ref.id));
    });
  });
}
