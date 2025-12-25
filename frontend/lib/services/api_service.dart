import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final String _baseUrl = kIsWeb || !defaultTargetPlatform.toString().contains('android') 
      ? 'http://localhost:8000/api/' 
      : 'http://10.0.2.2:8000/api/';

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}
