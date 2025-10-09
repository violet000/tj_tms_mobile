import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';
import 'package:tj_tms_mobile/core/config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tj_tms_mobile/core/utils/password_encrypt.dart';
import 'package:tj_tms_mobile/core/utils/util.dart' as app_utils;

/// 18082服务接口部分
class Service18082 {
  static const String vpsKey = 'network_vps_ip';

  final DioService _dioService;
  Map<String, dynamic> _deviceInfo = <String, dynamic>{};

  Service18082._(this._dioService);

  static Future<Service18082> create() async {
    final prefs = await SharedPreferences.getInstance();
    final vpsIp = prefs.getString(vpsKey) ?? '${Env.config.apiBaseUrl}:8082';
    final baseUrl = vpsIp.startsWith('http') ? vpsIp : 'http://$vpsIp';
    final dio = DioServiceManager().getService(baseUrl);
    // 指定接口使用固定 Basic token
    dio.setFixedTokenFor('/user-center/v2/user/faceLogin', 'Basic emhhbmdzYW46MTIzNDU2');
    
    // 尝试从SharedPreferences获取已保存的access_token
    final String? savedToken = prefs.getString('access_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      dio.setAccessToken(savedToken);
    }
    
    final service = Service18082._(dio);
    await service._loadDeviceInfo();
    return service;
  }

  Future<void> _loadDeviceInfo() async {
    final info = await app_utils.loadDeviceInfo();
    _deviceInfo = info;
  }

  /// 用户登陆
  /// @param username 用户名
  /// @param password 密码
  /// @param faceImage 人脸图片（可选）
  Future<Map<String, dynamic>> login(String username, String? password,
      [String? faceImage]) async {
    return _dioService.post(
      '/auth/callback/login/mobile',
      body: <String, dynamic>{
        'username': passwordEncrypt(username),
        'password': password != null
            ? passwordEncrypt(password, ENCRYPT_ENUM['MD5_SALT']!)
            : '',
        if (faceImage != null) 'faceImage': faceImage,
      },
    );
  }

  // 新的登录方式
  Future<Map<String, dynamic>> accountLogin(
      List<Map<String, dynamic>> loginParams) async {
    return _dioService.post(
      '/user-center/v2/user/faceLogin',
      body: loginParams,
    );
  }

  ///查询押运员编号查询线路及线路涉及机构信息
  Future<Map<String, dynamic>> getLineByEscortNo(dynamic escortNo,
      {int? mode}) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'escortNo': escortNo,
      // 'handheldNo': _deviceInfo['deviceId'],
      'handheldNo': 'c7aec416ab7f236a71495d2849a662229974bab16723e7a012e41d6998288001',
    };
    if (mode != null) {
      body['mode'] = mode;
    }
    return _dioService.post('/user-center/v2/user/qryLineByEscortNo',
        body: body);
  }

  /// 查询当前用户下的押运线路数据
  Future<Map<String, dynamic>> getEscortRouteToday(String username) async {
    return _dioService.get('/storage/escort-route/today',
        queryParameters: <String, String>{'username': username});
  }

  /// 查询当前金库下所有需要扫描的款箱列表
  Future<Map<String, dynamic>> getCashBoxList(String pointCode) async {
    return _dioService.get('/storage/cash-box/list',
        queryParameters: <String, String>{'pointCode': pointCode});
  }

  /// 更新当前扫描款箱的状态
  Future<dynamic> updateCashBoxStatus(List<dynamic> cashBoxList) async {
    return _dioService.post(
      '/manage-center/ps/outletHandover/phone',
      body: cashBoxList,
    );
  }

  /// 发送GPS信息
  Future<dynamic> sendGpsInfo(Map<String, dynamic> params) async {
    return _dioService.post(
      '/manage-center/v2/gps',
      body: params,
    );
  }

  /// 确认交接
  Future<Map<String, dynamic>> outletHandover(
      Map<String, dynamic> params) async {
    return _dioService.post(
      '/manage-center/v2/outletHandover',
      body: <String, dynamic>{
        'implNo': params['implNo'],
        'outTre': params['outTre'],
        'hander': params['hander'],
        'escortNo': params['escortNo'],
        'deliver': params['deliver'],
        'inconsistent': params['inconsistent'],
      },
    );
  }

  /// 更新金库状态
  Future<Map<String, dynamic>> updatePointStatus(
      String username, String password, String pointCode) async {
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
  Future<Map<String, dynamic>> getUserClrCenterList(
      Map<String, dynamic> params) async {
    return _dioService.get('tauro/v2/outsourcing/qryClrCenterNoByPerson',
        queryParameters: params);
  }

  /// 查询押运员基本信息
  Future<Map<String, dynamic>> getEscortByNo(String no) async {
    return _dioService.post(
      '/manage-center/v2/selectEscortByNo',
      body: <String, dynamic>{'no': no},
    );
  }

  /// 查询AGPS系统参数
  Future<Map<String, dynamic>> getAGPSParam(Map<String, dynamic> params) async {
    return _dioService.get('/param-center/v2/paramManage',
        queryParameters: params);
  }

  /// 重置密码
  Future<Map<String, dynamic>> resetPassword(
      String username, String newPsd, String password) async {
    return _dioService.post(
      '/user-center/v2/user/passwordByUser',
      body: <String, dynamic>{
        'username': username,
        'newPassword': newPsd,
        'password': password
      },
    );
  }
}
