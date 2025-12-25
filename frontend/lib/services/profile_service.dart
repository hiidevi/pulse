import 'dart:io';
import 'package:dio/dio.dart';
import 'api_service.dart';

class ProfileService {
  Future<Map<String, dynamic>> uploadProfilePhoto(File imageFile, int order) async {
    final String fileName = imageFile.path.split('/').last;
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      'order': order,
    });

    final response = await ApiService.dio.post('profile/photos/', data: formData);
    return response.data;
  }

  Future<void> deleteProfilePhoto(int photoId) async {
    await ApiService.dio.delete('profile/photos/$photoId/');
  }

  Future<Map<String, dynamic>> updateProfile({String? username, String? avatarEmoji}) async {
    final Map<String, dynamic> data = {};
    if (username != null) data['username'] = username;
    if (avatarEmoji != null) data['avatar_emoji'] = avatarEmoji;

    final response = await ApiService.dio.patch('auth/profile/', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getPublicProfile(int userId) async {
    final response = await ApiService.dio.get('users/$userId/');
    return response.data;
  }
}
