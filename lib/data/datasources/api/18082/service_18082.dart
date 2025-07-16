import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';
import 'package:tj_tms_mobile/core/utils/password_encrypt.dart';
import 'package:tj_tms_mobile/core/config/env.dart';

/// 登录(认证)API接口服务 - 18082服务接口部分
class Service18082 {

  Service18082() : _dioService = DioService(baseUrl: '${Env.config.apiBaseUrl}:18082');
  
  final DioService _dioService;

  Service18082._(this._dioService);

  static Future<Service18082> create() async {
    final config = await Env.config;
    return Service18082._(DioService(baseUrl: '${config.apiBaseUrl}:18082'));
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
  Future<Map<String, dynamic>> accountLogin(String username, String? password, String? image) async {
    return _dioService.post(
      '/auth/callback/login',
      body: <String, dynamic>{
        'username': username,
        'password': password,
        'image': image,
      },
    );
  }
  ///查询押运员编号查询线路及线路涉及机构信息
  Future <Map<String, dynamic>> getLineByEscortNo(String escortNo,{int? mode}) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'escortNo': escortNo,
    };
    if (mode != null) {
      body['mode'] = mode;
    }
    return _dioService.post('/user-center/v2/user/qryLineByEscortNo',body: body);
  }



  /// 查询当前用户下的押运线路数据
  Future <Map<String, dynamic>> getEscortRouteToday(String username) async {
    return _dioService.get('/storage/escort-route/today', queryParameters: <String, String>{'username': username});
  }

  /// 查询当前金库下所有需要扫描的款箱列表
  Future <Map<String, dynamic>> getCashBoxList(String pointCode) async {
    return _dioService.get('/storage/cash-box/list', queryParameters: <String, String>{'pointCode': pointCode});
  }

  /// 更新当前扫描款箱的状态
  Future<dynamic> updateCashBoxStatus(List<dynamic> cashBoxList) async {
    return _dioService.post(
      '/manage-center/ps/outletHandover/phone',
      body: cashBoxList,
    );
  }

  /// 交接款箱
  Future<Map<String, dynamic>> handoverCashBox(String pointCode, List<dynamic> cashBoxList) async {
    return _dioService.post(
      '/storage/cash-box/check?pointCode=$pointCode',
      body: <String, dynamic>{
        'cashBoxList': cashBoxList,
      },
    );
  }

  /// 更新金库状态
  Future<Map<String, dynamic>> updatePointStatus(String username, String password, String pointCode) async {
    return _dioService.post(
      '/storage/point/update-status',
      body: <String, dynamic>{
        'username': username,
        'password': password,
        'pointCode': pointCode,
      },
    );
  }

  /// 根据登录用户查询金库列表
  Future<Map<String, dynamic>> getUserClrCenterList(Map<String, dynamic> params) async {
    return _dioService.get('tauro/v2/outsourcing/qryClrCenterNoByPerson', queryParameters: params);
  }
}