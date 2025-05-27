import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  // 基础URL
  final String baseUrl = 'https://api.example.com'; // 替换为实际的API地址
  
  // 创建Dio实例
  late final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
    headers: {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer $token',
    },
  ));

  // GET请求
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  // POST请求
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.post(
        path,
        data: body,
      );
      
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  // 处理响应
  dynamic _handleResponse(Response response) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      return response.data;
    } else {
      throw HttpException(
        response.statusCode!,
        response.data.toString(),
      );
    }
  }

  // 处理错误
  void _handleError(dynamic error) {
    if (kDebugMode) {
      print('HTTP Error: $error');
    }
    if (error is DioException) {
      throw HttpException(
        error.response?.statusCode ?? 500,
        error.message ?? 'Unknown error occurred',
      );
    }
    throw HttpException(
      500,
      error.toString(),
    );
  }
}

// 自定义HTTP异常
class HttpException implements Exception {
  final int statusCode;
  final String message;

  HttpException(this.statusCode, this.message);

  @override
  String toString() => 'HttpException: $statusCode - $message';
} 