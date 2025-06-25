import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';
import 'package:tj_tms_mobile/core/utils/password_encrypt.dart';
import 'package:tj_tms_mobile/core/config/env.dart';

/// 登录(认证)API接口服务 - 18082服务接口部分
class Service18082 {

  Service18082() : _dioService = DioServiceManager().getService('${Env.config.apiBaseUrl}:8082');
  
  final DioService _dioService;

  Service18082._(this._dioService);

  static Future<Service18082> create() async {
    final config = await Env.config;
    return Service18082._(DioServiceManager().getService('${config.apiBaseUrl}:8082'));
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
  Future<Map<String, dynamic>> accountLogin(String username, String? password) async {
    return _dioService.post(
      '/auth/callback/login',
      body: <String, dynamic>{
        'username': username,
        'password': password
      },
    );
  }

  // 查询押运员详细信息
  Future <Map<String, dynamic>> getEscortInfo(String escortName) async {
    return _dioService.get('/manage-center/v2/escortInfo', queryParameters: <String, String>{'escortName': escortName});
  }

  // 根据押运员编号查询线路及线路涉及机构信息
  Future <Map<String, dynamic>> qryLineByEscortNo(String escortNo) async {
    return _dioService.post('/user-center/v2/user/qryLineByEscortNo', body: <String, String>{'escortNo': escortNo});
  }

  // 查询入库交接信息
  Future <Map<String, dynamic>> getInHandover(String orgNo) async {
    return _dioService.get('/manage-center/v2/inHandover', queryParameters: <String, String>{'orgNo': orgNo});
  }

  // 查询出库交接信息
  Future <Map<String, dynamic>> getOutletHandover(String orgNo) async {
    return _dioService.get('/manage-center/v2/outletHandover', queryParameters: <String, String>{'orgNo': orgNo});
  }

  // 获取线路组织机构列表
  Future <Map<String, dynamic>> getLineOrgList(String orgNo) async {
    return _dioService.get('/manage-center/v2/lineOrgList', queryParameters: <String, String>{'orgNo': orgNo});
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
  Future<Map<String, dynamic>> updateCashBoxStatus(String boxCode, int scanStatus) async {
    return _dioService.post(
      '/storage/cash-box/scan-status',
      body: <String, dynamic>{
        'boxCode': boxCode,
        'scanStatus': scanStatus,
      },
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