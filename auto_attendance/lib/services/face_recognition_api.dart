import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class FaceRecognitionAPI {
  // Change this to your computer's IP address when running FastAPI
  static const String baseUrl = "http://129.113.225.39:8000";

  // Alternative: Use your computer's local IP if testing on phone
  // static const String baseUrl = "http://192.168.1.XXX:8000";

  /// Register face using Firebase Storage URLs (NEW METHOD)
  ///
  /// [uid] - User ID from Firebase
  /// [leftUrl] - Firebase Storage URL for left image
  /// [rightUrl] - Firebase Storage URL for right image
  /// [frontUrl] - Firebase Storage URL for front image
  static Future<bool> registerFaceFromUrls({
    required String uid,
    required String leftUrl,
    required String rightUrl,
    required String frontUrl,
  }) async {
    try {
      print('🔵 API: Registering face from Firebase URLs for user $uid');

      final response = await http.post(
        Uri.parse('$baseUrl/register-from-urls'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'uid': uid,
          'left_url': leftUrl,
          'right_url': rightUrl,
          'front_url': frontUrl,
        },
      );

      print('🔵 API Response Status: ${response.statusCode}');
      print('🔵 API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print(
              '✅ API: Face registered successfully (${data['downloaded']}/3 images)');
          return true;
        } else {
          print('❌ API: Registration failed - ${data['message']}');
          return false;
        }
      } else {
        print('❌ API: Registration failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ API ERROR: $e');
      return false;
    }
  }

  /// Register a face image with the API (OLD METHOD - still works)
  ///
  /// [uid] - User ID from Firebase
  /// [imageBytes] - Raw image bytes
  /// [fileName] - Name of the file (e.g., "front.jpg")
  static Future<bool> registerFace({
    required String uid,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      print('🔵 API: Registering face for user $uid');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/register'),
      );

      request.fields['uid'] = uid;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('🔵 API Response: $responseBody');

      if (response.statusCode == 200) {
        print('✅ API: Face registered successfully');
        return true;
      } else {
        print('❌ API: Registration failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ API ERROR: $e');
      return false;
    }
  }

  /// Recognize a face in an image
  ///
  /// [imageBytes] - Raw image bytes from camera or file
  /// Returns the recognized user ID or null if not recognized
  static Future<String?> recognizeFace(Uint8List imageBytes) async {
    try {
      print('🔵 API: Recognizing face...');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/recognize'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'capture.jpg',
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      print('🔵 API Response: $data');

      if (data['recognized'] == true && data['uid'] != null) {
        print('✅ API: Face recognized as ${data['uid']}');
        return data['uid'];
      } else {
        print('❌ API: No face recognized');
        return null;
      }
    } catch (e) {
      print('❌ API ERROR: $e');
      return null;
    }
  }

  /// Test if the API is running
  static Future<bool> testConnection() async {
    try {
      print('🔵 API: Testing connection to $baseUrl');
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        print('✅ API: Connection successful');
        print('Response: ${response.body}');
        return true;
      } else {
        print('❌ API: Connection failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ API: Cannot connect - $e');
      return false;
    }
  }

  /// Get list of registered users from API (for debugging)
  static Future<Map<String, dynamic>?> getRegisteredUsers() async {
    try {
      print('🔵 API: Getting registered users...');
      final response = await http.get(Uri.parse('$baseUrl/registered-users'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ API: ${data['total_users']} users registered');
        return data;
      } else {
        print('❌ API: Failed to get users');
        return null;
      }
    } catch (e) {
      print('❌ API ERROR: $e');
      return null;
    }
  }
}
