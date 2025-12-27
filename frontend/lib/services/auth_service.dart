import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthService {
  final Dio _dio = ApiService.dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('auth/login/', data: {
        'email': email,
        'password': password,
      });
      if (response.statusCode == 200) {
        final data = response.data;
        await ApiService.persistToken(data['access']);
        return data;
      }
      throw Exception('Failed to login');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signup(String username, String email, String password, {String? avatarEmoji}) async {
    try {
      final response = await _dio.post('auth/signup/', data: {
        'username': username,
        'email': email,
        'password': password,
        if (avatarEmoji != null) 'avatar_emoji': avatarEmoji,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('auth/profile/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
