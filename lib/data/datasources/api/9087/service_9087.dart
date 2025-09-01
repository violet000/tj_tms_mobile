import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';
import 'package:tj_tms_mobile/core/config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 9087服务接口部分
class Service9087 {
  static const String vmsKey = 'network_vms_ip';

  final DioService _dioService;

  Service9087._(this._dioService);

  static Future<Service9087> create() async {
    final prefs = await SharedPreferences.getInstance();
    final vmsIp = prefs.getString(vmsKey) ?? '${Env.config.apiBaseUrl}:8082';
    final baseUrl = vmsIp.startsWith('http') ? vmsIp : 'http://$vmsIp';
    final dio = DioServiceManager().getService(baseUrl);
    // 指定接口使用固定 Basic token
    dio.setFixedTokenFor('/manage-center/v2/gps', 'Basic emhhbmdzYW46MTIzNDU2');
    final service = Service9087._(dio);
    return service;
  }

  /// 发送GPS信息
  Future<dynamic> sendGpsInfo(Map<String, dynamic> params) async {
    return _dioService.post(
      '/manage-center/v2/gps',
      body: params,
    );
  }
}
