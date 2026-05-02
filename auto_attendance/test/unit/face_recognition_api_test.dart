// test/unit/face_recognition_api_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_attendance_webapp/services/face_recognition_api.dart';

void main() {
  group('FaceRecognitionAPI Tests', () {
    
    test('testConnection function exists', () {
      // Test that the function exists
      expect(FaceRecognitionAPI.testConnection, isA<Function>());
    });

    test('recognizeFace function exists', () {
      // Test that the recognizeFace method exists
      expect(FaceRecognitionAPI.recognizeFace, isA<Function>());
    });

    test('registerFaceFromUrls function exists', () {
      // Test that the registerFaceFromUrls method exists
      expect(FaceRecognitionAPI.registerFaceFromUrls, isA<Function>());
    });

    test('baseUrl is configured', () {
      // Test that baseUrl is set
      expect(FaceRecognitionAPI.baseUrl, isNotEmpty);
    });
  });
}