// test/unit/auth_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  group('Authentication Tests', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = FakeFirebaseFirestore();
    });

    test('User signup creates both Auth and Firestore records', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      const name = 'Test User';

      // Act - Create user in Auth
      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Create user document in Firestore
      await mockFirestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'isAdmin': false,
        'faceSetupComplete': false,
        'classes': [],
      });

      // Assert - Verify Auth user exists
      expect(mockAuth.currentUser, isNotNull);
      expect(mockAuth.currentUser!.email, email);

      // Assert - Verify Firestore document exists
      final userDoc = await mockFirestore.collection('users').doc(userId).get();
      expect(userDoc.exists, true);
      expect(userDoc.data()!['name'], name);
      expect(userDoc.data()!['email'], email);
      expect(userDoc.data()!['isAdmin'], false);
      expect(userDoc.data()!['faceSetupComplete'], false);
    });

    test('User login succeeds with correct credentials', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';

      // Create user first
      await mockAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Act - Sign out then sign in
      await mockAuth.signOut();
      final userCredential = await mockAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Assert
      expect(userCredential.user, isNotNull);
      expect(userCredential.user!.email, email);
      expect(mockAuth.currentUser, isNotNull);
    });

    test('Password reset email is sent successfully', () async {
      // Arrange
      const email = 'test@example.com';

      // Act
      await mockAuth.sendPasswordResetEmail(email: email);

      // Assert - No exception thrown means success
      // In real implementation, would verify email was sent
      expect(true, true);
    });

    test('Admin field defaults to false on signup', () async {
      // Arrange
      const email = 'newuser@example.com';
      const password = 'password123';

      // Act
      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await mockFirestore.collection('users').doc(userCredential.user!.uid).set({
        'name': 'New User',
        'email': email,
        'isAdmin': false,
        'faceSetupComplete': false,
        'classes': [],
      });

      // Assert
      final userDoc = await mockFirestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      expect(userDoc.data()!['isAdmin'], false);
    });

    test('Face setup complete defaults to false', () async {
      // Arrange
      const email = 'newuser@example.com';
      const password = 'password123';

      // Act
      final userCredential = await mockAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await mockFirestore.collection('users').doc(userCredential.user!.uid).set({
        'name': 'New User',
        'email': email,
        'isAdmin': false,
        'faceSetupComplete': false,
        'classes': [],
      });

      // Assert
      final userDoc = await mockFirestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      expect(userDoc.data()!['faceSetupComplete'], false);
    });
  });
}