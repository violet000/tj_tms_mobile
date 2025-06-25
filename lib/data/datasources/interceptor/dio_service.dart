import 'dart:convert';
import 'dart:core';
import 'package:dio/dio.dart';
import 'package:tj_tms_mobile/core/errors/exceptions.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';

class DioService {
  final String baseUrl;
  final Dio _dio;
  String? _accessToken;

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
          // 添加 access_token 到请求头
          if (_accessToken != null && _accessToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
            AppLogger.debug('添加 Authorization 头: Bearer $_accessToken');
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
          AppLogger.apiResponse(
            '${response.requestOptions.baseUrl}${response.requestOptions.path}',
            response.data,
            statusCode: response.statusCode,
          );
          
          handler.next(response);
        },
        onError: (error, handler) {
          // 记录错误日志
          AppLogger.apiResponse(
            '${error.requestOptions.baseUrl}${error.requestOptions.path}',
            null,
            statusCode: error.response?.statusCode,
            error: error.message,
          );
          
          handler.next(error);
        },
      ),
    );
  }

  /// 设置 access_token
  void setAccessToken(String? token) {
    _accessToken = token;
    AppLogger.info('设置 access_token: ${token != null ? '${token.substring(0, 10)}...' : 'null'}');
  }

  /// 清除 access_token
  void clearAccessToken() {
    _accessToken = null;
    AppLogger.info('清除 access_token');
  }

  /// 获取当前的 access_token
  String? getAccessToken() => _accessToken;

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
    AppLogger.info('为所有 DioService 设置 access_token');
  }

  /// 清除所有服务的 access_token
  void clearAccessTokenForAll() {
    for (var service in _services.values) {
      service.clearAccessToken();
    }
    AppLogger.info('清除所有 DioService 的 access_token');
  }

  /// 获取所有服务实例
  List<DioService> getAllServices() {
    return _services.values.toList();
  }

  /// 清除所有服务实例
  void clearAllServices() {
    _services.clear();
    AppLogger.info('清除所有 DioService 实例');
  }
}

/*
使用示例：

1. 登录成功后设置 token：
```dart
// 在登录页面中
void _saveLoginData(String username, Map<String, dynamic> loginResult) {
  _verifyTokenProvider.setToken(loginResult['access_token'].toString());
  _verifyTokenProvider.setUserData(<String, dynamic>{
    'username': username,
    'access_token': loginResult['access_token'],
    'refresh_token': loginResult['refresh_token'],
    'expires_in': loginResult['expires_in'],
    'token_type': loginResult['token_type'],
    'scope': loginResult['scope'],
  });
}
```

2. 创建服务实例（会自动获取到带有 token 的 DioService）：
```dart
class MyService {
  final DioService _dioService;
  
  MyService() : _dioService = DioServiceManager().getService('https://api.example.com');
  
  Future<Map<String, dynamic>> getData() async {
    // 这个请求会自动带上 Authorization: Bearer <token> 头
    return _dioService.get('/api/data');
  }
}
```

3. 登出时清除 token：
```dart
void logout() {
  _verifyTokenProvider.clearToken();
  // 这会自动清除所有 DioService 的 token
}
```

4. 手动设置 token（如果需要）：
```dart
// 直接操作 DioServiceManager
DioServiceManager().setAccessTokenForAll('your_token_here');

// 或者操作单个服务
final service = DioServiceManager().getService('https://api.example.com');
service.setAccessToken('your_token_here');
```

5. 检查当前 token：
```dart
// 从 Provider 获取
String? token = _verifyTokenProvider.getToken();

// 从服务获取
String? token = service.getAccessToken();
```

这个系统的优势：
- 自动管理：登录后自动为所有服务设置 token
- 统一管理：所有 DioService 实例共享同一个 token
- 日志记录：所有请求和响应都有详细的日志
- 易于扩展：可以轻松添加新的服务
- 类型安全：使用强类型确保代码质量
*/