import 'http_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final HttpService _http = HttpService();

  // 登录
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    return await _http.post('/login', body: {
      'username': username,
      'password': password,
    });
  }

  // 上传照片
  Future<Map<String, dynamic>> uploadPhoto({
    required String userId,
    required String photoPath,
  }) async {
    // 这里需要实现文件上传的逻辑
    return await _http.post('/upload-photo', body: {
      'userId': userId,
      'photoPath': photoPath,
    });
  }

  // 验证用户
  Future<Map<String, dynamic>> verifyUser({
    required String userId,
    required String verificationType, // 'account' 或 'photo'
    required Map<String, dynamic> data,
  }) async {
    return await _http.post('/verify-user', body: {
      'userId': userId,
      'verificationType': verificationType,
      ...data,
    });
  }
} 