import 'dart:convert';
import 'dart:core';
import 'package:dio/dio.dart';
import 'package:tj_tms_mobile/core/errors/exceptions.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:tj_tms_mobile/core/utils/global_navigator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tj_tms_mobile/services/location_polling_manager.dart';

class DioService {
  final String baseUrl;
  final Dio _dio;
  String? _accessToken;
  // 指定接口使用固定 token 的匹配规则：key 为匹配 Pattern（String 或 RegExp），value 为固定 token
  final Map<Pattern, String> _fixedTokenByPattern = <Pattern, String>{};

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
        )) {
    _setupInterceptors();
  }

  /// 设置拦截器
  void _setupInterceptors() {
    // 请求拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 添加Authorization到请求头（指定接口优先使用固定token）
          final String fullUrl = '${options.baseUrl}${options.path}';
          String? tokenToUse;
          // 命中任一匹配规则则使用固定 token
          _fixedTokenByPattern.forEach((Pattern pattern, String token) {
            if (fullUrl.contains(pattern)) {
              tokenToUse = token;
            }
          });
          tokenToUse ??= _accessToken;
          if (tokenToUse != null && tokenToUse!.isNotEmpty) {
            final String t = tokenToUse!.trim();
            final bool hasScheme = t.startsWith('Basic ') || t.startsWith('Bearer ');
            options.headers['Authorization'] = hasScheme ? t : 'Bearer ' + t;
          }
          
          // 记录请求日志
          AppLogger.network(
            options.method,
            '${options.baseUrl}${options.path}',
            headers: options.headers,
            body: options.data,
          );
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          // 记录响应日志
          // AppLogger.apiResponse(
          //   '${response.requestOptions.baseUrl}${response.requestOptions.path}',
          //   response.data,
          //   statusCode: response.statusCode,
          // );
          
          handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.apiResponse(
            '${error.requestOptions.baseUrl}${error.requestOptions.path}',
            null,
            statusCode: error.response?.statusCode,
            error: error.message,
          );
          
          // 处理401认证失败，自动跳转到登录页面
          if (error.response?.statusCode == 401) {
            _handleAuthFailure();
          }
          
          handler.next(error);
        },
      ),
    );
  }

  /// 设置 access_token
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// 清除 access_token
  void clearAccessToken() {
    _accessToken = null;
  }

  /// 获取当前的 access_token
  String? getAccessToken() => _accessToken;

  /// 处理认证失败，清除token并跳转到登录页面
  void _handleAuthFailure() async {
    // 清除当前token
    clearAccessToken();
    
    // 清除所有服务的token
    DioServiceManager().clearAccessTokenForAll();
    
    // 清除SharedPreferences中的token
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
    } catch (e) {
      AppLogger.error('清除SharedPreferences中的token失败: $e');
    }
    
    // 确保AGPS位置轮询服务继续运行
    _ensureLocationPollingContinues();
    
    // 使用全局导航器跳转到登录页面
    GlobalNavigator.navigateToLogin();
    
  }

  /// 确保位置轮询服务在认证失效时继续运行
  void _ensureLocationPollingContinues() {
    try {
      final locationPollingManager = LocationPollingManager();
    } catch (e) {
      AppLogger.error('确保AGPS位置轮询服务继续运行时出错: $e');
    }
  }

  /// 为匹配到的接口设置固定 token（pattern 可为子串或正则）
  void setFixedTokenFor(Pattern pattern, String token) {
    _fixedTokenByPattern[pattern] = token;
  }

  /// 移除某条固定 token 规则
  void removeFixedTokenFor(Pattern pattern) {
    _fixedTokenByPattern.remove(pattern);
  }

  /// 清空所有固定 token 规则
  void clearFixedTokenRules() {
    _fixedTokenByPattern.clear();
  }

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

  Future<Map<String, dynamic>> post(String endpoint, {dynamic body}) async {
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

/// 全局 DioService 管理器
class DioServiceManager {
  static final DioServiceManager _instance = DioServiceManager._internal();
  factory DioServiceManager() => _instance;
  DioServiceManager._internal();

  final Map<String, DioService> _services = {};

  /// 获取或创建 DioService 实例
  DioService getService(String baseUrl) {
    if (!_services.containsKey(baseUrl)) {
      _services[baseUrl] = DioService(baseUrl: baseUrl);
    }
    return _services[baseUrl]!;
  }

  /// 为所有服务设置 access_token
  void setAccessTokenForAll(String? token) {
    for (var service in _services.values) {
      service.setAccessToken(token);
    }
  }

  /// 清除所有服务的 access_token
  void clearAccessTokenForAll() {
    for (var service in _services.values) {
      service.clearAccessToken();
    }
  }

  /// 获取所有服务实例
  List<DioService> getAllServices() {
    return _services.values.toList();
  }

  /// 清除所有服务实例
  void clearAllServices() {
    _services.clear();
  }
}