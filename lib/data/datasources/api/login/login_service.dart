import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';
import 'package:tj_tms_mobile/core/utils/password_encrypt.dart';
import 'package:tj_tms_mobile/core/config/env.dart';

/// 登录(认证)API接口服务 - 18082服务接口部分
class LoginService {

  LoginService() : _dioService = DioService(baseUrl: '${Env.config.apiBaseUrl}:18082');
  
  final DioService _dioService;

  LoginService._(this._dioService);

  static Future<LoginService> create() async {
    final config = await Env.config;
    return LoginService._(DioService(baseUrl: '${config.apiBaseUrl}:18082'));
  }

  /// 用户登陆
  /// @param username 用户名
  /// @param password 密码
  /// @param faceImage 人脸图片（可选）
  Future<Map<String, dynamic>> login(String username, String? password, [String? faceImage]) async {
    return _dioService.post(
      '/auth/callback/login/mobile',
      body: <String, dynamic>{
        'username': passwordEncrypt(username),
        'password': password != null ? passwordEncrypt(password, ENCRYPT_ENUM['MD5_SALT']!) : '',
        if (faceImage != null) 'faceImage': faceImage,
      },
    );
  }
  
  /// 老的登录方式
  Future<Map<String, dynamic>> accountLogin(String username, String password) async {
    return _dioService.post(
      '/auth/callback/login',
      body: <String, dynamic>{
        'username': username,
        'password': password,
      },
    );
  }

  /// 查询当前登陆的用户详细信息
  Future<Map<String, dynamic>> detail() async {
    return _dioService.get('user-center/v2/user/detail');
  }

  /// 根据登录用户查询金库列表
  Future<Map<String, dynamic>> getUserClrCenterList(Map<String, dynamic> params) async {
    return _dioService.get('tauro/v2/outsourcing/qryClrCenterNoByPerson', queryParameters: params);
  }
}