import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String _baseUrl = 'https://pulse-production-f3ba.up.railway.app/api/';

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
