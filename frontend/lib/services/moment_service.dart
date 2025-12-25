import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/moment.dart';

class MomentService {
  final Dio _dio = ApiService.dio;

  Future<Moment> sendMoment(int receiverId, String text, String emoji, {String? imagePath}) async {
    try {
      final formData = FormData.fromMap({
        'receiver_id': receiverId,
        'text': text,
        'emoji': emoji,
        if (imagePath != null)
          'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dio.post('moments/send/', data: formData);
      return Moment.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Moment>> getMemories() async {
    try {
      final response = await _dio.get('moments/');
      final List data = response.data;
      return data.map((json) => Moment.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendReply(int momentId, String text, String emoji) async {
    try {
      await _dio.post('moments/reply/', data: {
        'parent_moment_id': momentId,
        'text': text,
        'emoji': emoji,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRecentActivity() async {
    try {
      final response = await _dio.get('activity/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Moment>> getConversationHistory(int userId) async {
    try {
      final response = await _dio.get('conversations/$userId/');
      return (response.data as List).map((m) => Moment.fromJson(m)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
