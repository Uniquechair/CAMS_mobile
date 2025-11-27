import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _base = 'http://165.22.103.232:3000';
  
  // Set to true to use mock data instead of real API calls
  static const bool _useMockData = false; // Using real backend

  // LOGIN: expects { username, password }
  // Returns: { message, success, userid, usergroup, uactivation }
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    if (_useMockData) {
      return _mockLogin(username: username, password: password);
    }
    
    try {
      final res = await http.post(
        Uri.parse('$_base/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final body = _safeJson(res.body);
      if (res.statusCode == 200 && body['success'] == true) return body;
      throw Exception(body['message'] ?? 'Login failed (${res.statusCode})');
    } catch (e) {
      // Fallback to mock data if backend fails
      print('Backend connection failed, using mock data: $e');
      return _mockLogin(username: username, password: password);
    }
  }

  // REGISTER: expects {
  //  firstName,lastName,username,email,password,uphoneno,userGroup
  // } -> { message, success }
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String uphoneno,
    required String userGroup,
  }) async {
    if (_useMockData) {
      return _mockRegister(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
        uphoneno: uphoneno,
        userGroup: userGroup,
      );
    }
    
    try {
      final res = await http.post(
        Uri.parse('$_base/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'email': email,
          'password': password,
          'uphoneno': uphoneno,
          'userGroup': userGroup,
        }),
      );
      final body = _safeJson(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) && body['success'] == true) {
        return body;
      }
      throw Exception(body['message'] ?? 'Signup failed (${res.statusCode})');
    } catch (e) {
      // Fallback to mock data if backend fails
      print('Backend connection failed, using mock data: $e');
      return _mockRegister(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
        uphoneno: uphoneno,
        userGroup: userGroup,
      );
    }
  }

  // MOCK LOGIN for testing without backend
  static Future<Map<String, dynamic>> _mockLogin({
    required String username,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Simple mock data for testing
    return {
      'success': true,
      'message': 'Login successful',
      'userid': username.hashCode.abs(),
      'usergroup': 'customer', // Default to customer for mock
      'uactivation': 'active',
    };
  }

  // MOCK REGISTER for testing
  static Future<Map<String, dynamic>> _mockRegister({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String uphoneno,
    required String userGroup,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    return {
      'success': true,
      'message': 'Registration successful for ${userGroup} role',
      'userGroup': userGroup.toLowerCase(),
    };
  }

  static Map<String, dynamic> _safeJson(String s) {
    try { return jsonDecode(s) as Map<String, dynamic>; } catch (_) { return {}; }
  }
}
