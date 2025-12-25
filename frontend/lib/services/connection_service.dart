import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/user.dart';

class ConnectionService {
  final Dio _dio = ApiService.dio;

  Future<List<User>> searchUsers(String query) async {
    try {
      final response = await _dio.get('users/search/', queryParameters: {'query': query});
      final List data = response.data;
      return data.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendConnectionRequest(int receiverId) async {
    try {
      await _dio.post('connections/request/', data: {'receiver_id': receiverId});
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final response = await _dio.get('connections/', queryParameters: {'status': 'PENDING'});
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> respondToConnection(int connectionId, String status) async {
    try {
      await _dio.post('connections/respond/', data: {
        'connection_id': connectionId,
        'status': status,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFriends() async {
    try {
      final response = await _dio.get('connections/', queryParameters: {'status': 'ACCEPTED'});
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
