import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';
import 'package:tj_tms_mobile/core/utils/password_encrypt.dart';

/// 登录API接口服务
class LoginService {
  final DioService _dioService;

  LoginService() : _dioService = DioService(baseUrl: 'http://10.34.12.164:18082'); // TODO: 后续需要做测试/开发/生产环境切换

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

  /// 查询当前登陆的用户详细信息
  Future<Map<String, dynamic>> detail() async {
    return _dioService.get('user-center/v2/user/detail');
  }

  /// 根据登录用户查询金库列表
  Future<Map<String, dynamic>> getUserClrCenterList(Map<String, dynamic> params) async {
    return _dioService.get('tauro/v2/outsourcing/qryClrCenterNoByPerson', queryParameters: params);
  }
}