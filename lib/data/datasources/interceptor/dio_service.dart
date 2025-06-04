import 'dart:convert';
import 'dart:core';
import 'package:dio/dio.dart';
import 'package:tj_tms_mobile/core/errors/exceptions.dart';

class DioService {
  final String baseUrl;
  final Dio _dio;

  DioService({
    required this.baseUrl,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));

  // 基础请求方法
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: queryParameters,
      );
      
      if (response.statusCode == 200) {
        if (response.data?.containsKey('retCode') == true) {
          if (response.data?['retCode'] == '000000') {
            return response.data ?? <String, dynamic>{};
          } else {
            throw BusinessException(
              message: (response.data?['retMsg'] ?? '请求失败').toString(),
              code: (response.data?['retCode'] ?? 'REQUEST_${response.statusCode}').toString(),
            );
          }
        }
        return response.data ?? <String, dynamic>{};
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: '认证失败，请重新登录',
          code: 'AUTH_401',
        );
      } else if (response.statusCode! >= 500) {
        throw ServerException(
          message: '服务器错误',
          code: 'SERVER_${response.statusCode}',
        );
      } else {
        throw BusinessException(
          message: '请求失败',
          code: 'REQUEST_${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException(
          message: '网络连接超时',
          code: 'NETWORK_TIMEOUT',
          originalError: e,
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          message: '网络连接失败',
          code: 'NETWORK_ERROR',
          originalError: e,
        );
      }
      throw ServerException(
        message: '请求失败',
        code: 'REQUEST_ERROR',
        originalError: e,
      );
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException(
        message: '未知错误',
        code: 'UNKNOWN_ERROR',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: body,
      );
      
      if (response.statusCode == 200) {
        if (response.data?.containsKey('retCode') == true) {
          if (response.data?['retCode'] == '000000') {
            return response.data ?? <String, dynamic>{};
          } else {
            throw BusinessException(
              message: (response.data?['retMsg'] ?? '请求失败').toString(),
              code: (response.data?['retCode'] ?? 'REQUEST_${response.statusCode}').toString(),
            );
          }
        }
        return response.data ?? <String, dynamic>{};
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: '认证失败，请重新登录',
          code: 'AUTH_401',
        );
      } else if (response.statusCode! >= 500) {
        throw ServerException(
          message: '服务器错误',
          code: 'SERVER_${response.statusCode}',
        );
      } else {
        throw BusinessException(
          message: '请求失败',
          code: 'REQUEST_${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException(
          message: '网络连接超时',
          code: 'NETWORK_TIMEOUT',
          originalError: e,
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          message: '网络连接失败',
          code: 'NETWORK_ERROR',
          originalError: e,
        );
      }
      throw ServerException(
        message: '请求失败',
        code: 'REQUEST_ERROR',
        originalError: e,
      );
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ServerException(
        message: '未知错误',
        code: 'UNKNOWN_ERROR',
        originalError: e,
      );
    }
  }
}