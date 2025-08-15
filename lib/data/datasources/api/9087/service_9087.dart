import 'dart:io';
import 'package:dio/dio.dart';
import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';
import 'package:tj_tms_mobile/core/config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 9087服务接口部分
class Service9087 {
  static const String vmsKey = 'network_vms_ip';

  final DioService _dioService;
  final String _baseUrl;

  Service9087._(this._dioService, this._baseUrl);

  static Future<Service9087> create() async {
    final prefs = await SharedPreferences.getInstance();
    final vmsIp = prefs.getString(vmsKey) ?? '${Env.config.apiBaseUrl}:9087';
    final baseUrl = vmsIp.startsWith('http') ? vmsIp : 'http://$vmsIp';
    return Service9087._(
      DioServiceManager().getService(baseUrl),
      baseUrl,
    );
  }

  /// 上传地标文件
  Future<Map<String, dynamic>> addLocationByFile(File file) async {
    FormData formData = FormData.fromMap(<String, dynamic>{
      'file': await MultipartFile.fromFile(file.path,
          filename: file.path.split('/').last),
    });
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    final response = await dio.post<Map<String, dynamic>>(
      '/storage/v2/location/addLocationByFile',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data ?? <String, dynamic>{};
  }

  /// 通用FormData上传
  Future<Map<String, dynamic>> addLocationByFormData(FormData formData) async {
    final dio = Dio(BaseOptions(baseUrl: _baseUrl));
    final response = await dio.post<Map<String, dynamic>>(
      '/storage/v2/location/addLocationByFile',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data ?? <String, dynamic>{};
  }

  /// 新增地标
  // id - 地标编号
  // areaId - 所属库区id
  // areaName - 所属库区名称
  // clrCenterNo - 所属库编号（默认AA）
  // locationType - 地标类型 :1-障碍物（详情见库区类型文档）
  // status - 状态
  // note - 备注
  // length - 长度
  // width - 宽度
  // xplace - x坐标
  // yplace - y坐标
  // zplace - z坐标
  Future<Map<String, dynamic>> addLocation(Map<String, dynamic> params) async {
    return _dioService.post('/storage/v2/location/addLocation', body: params);
  }

  /// 修改地标
  // id - 地标编号
  // areaId - 所属库区id
  // areaName - 所属库区名称
  // clrCenterNo - 所属库编号（默认AA）
  // locationType - 地标类型 :1-障碍物（详情见库区类型文档）
  // status - 状态
  // note - 备注
  // length - 长度
  // width - 宽度
  // xplace - x坐标
  // yplace - y坐标
  // zplace - z坐标
  Future<Map<String, dynamic>> updateLocation(
      Map<String, dynamic> params) async {
    return _dioService.post('/storage/v2/location/updateLocation',
        body: params);
  }

  /// 地标管理-批量删除
  /// 参数：
  /// 批量删除地标信息（参数为List<String>）
  Future<Map<String, dynamic>> deleteBatch(List<String> ids) async {
    return _dioService.post('/storage/v2/location/deleteBatch', body: ids);
  }

  /// 仓储库区库位查询
  Future<Map<String, dynamic>> qryWarehousing(String areaId) async {
    return _dioService.get('/storage/v2/area/qryWarehousing',
        queryParameters: <String, String>{'areaId': areaId});
  }

  /// 仓储库区库位查询
  Future<Map<String, dynamic>> qryWarehousing1(String areaId) async {
    // return _dioService.get('/storage/v2/area/qryWarehousing',
    //     queryParameters: <String, String>{'areaId': areaId});
    return Map<String, dynamic>.from(<String, dynamic>{
      "retCode": "000000",
      "retMsg": "成功",
      "retList": [
        {
          "id": "A001",
          "clrCenterNo": "001",
          "type": "1",
          "name": "存储一区",
          "status": 1,
          "note": "测试",
          "floor": "1-1",
          "areaLength": "9",
          "areaWidth": "7",
          "x": "1",
          "y": "1",
          "z": "1",
          "storageLocationDTOS": [
            {
              "id": "444170AA246605",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246605",
              "zplace": "1",
              "shelfId": "SP0001"
            },
            {
              "id": "444170AA246606",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246606",
              "zplace": "1",
              "shelfId": "SP0002"
            },
            {
              "id": "444170AA246607",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246607",
              "zplace": "1",
              "shelfId": "SP0003"
            },
            {
              "id": "444170AA246608",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246608",
              "zplace": "1",
              "shelfId": "SP0004"
            },
            {
              "id": "444170AA246609",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246609",
              "zplace": "1",
              "shelfId": "SP0005"
            },
            {
              "id": "444170AA246610",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246610",
              "zplace": "1",
              "shelfId": "SP0006"
            },
            {
              "id": "444170AA246611",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246611",
              "zplace": "1",
              "shelfId": "SP0007"
            },
            {
              "id": "444170AA246612",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246612",
              "zplace": "1",
              "shelfId": "SP0008"
            },
            {
              "id": "444170AA246613",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246613",
              "zplace": "1",
              "shelfId": "SP0009"
            },
            {
              "id": "444170AA246614",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 2,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246614",
              "zplace": "1",
              "shelfId": "SP0010"
            },
            {
              "id": "444170AA246615",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246615",
              "zplace": "1",
              "shelfId": "SP0011"
            },
            {
              "id": "444170AA246616",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 2,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246616",
              "zplace": "1",
              "shelfId": "SP0012"
            },
            {
              "id": "444170AA246617",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246617",
              "zplace": "1",
              "shelfId": "SP0013"
            },
            {
              "id": "444170AA246618",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246618",
              "zplace": "1",
              "shelfId": "SP0014"
            },
            {
              "id": "444170AA246619",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 3,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246619",
              "zplace": "1",
              "shelfId": "SP0015"
            },
            {
              "id": "444170AA246620",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246620",
              "zplace": "1",
              "shelfId": "SP0016"
            },
            {
              "id": "444170AA246621",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 2,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246621",
              "zplace": "1",
              "shelfId": "SP0017"
            },
            {
              "id": "444170AA246622",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246622",
              "zplace": "1",
              "shelfId": "SP0018"
            },
            {
              "id": "444170AA246623",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246623",
              "zplace": "1",
              "shelfId": "SP0019"
            },
            {
              "id": "444170AA246624",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246624",
              "zplace": "1",
              "shelfId": "SP0020"
            },
            {
              "id": "444170AA246625",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246625",
              "zplace": "1",
              "shelfId": "SP0021"
            },
            {
              "id": "444170AA246626",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246626",
              "zplace": "1",
              "shelfId": "SP0022"
            },
            {
              "id": "444170AA246627",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246627",
              "zplace": "1",
              "shelfId": "SP0023"
            },
            {
              "id": "444170AA246628",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246628",
              "zplace": "1",
              "shelfId": "SP0024"
            },
            {
              "id": "444170AA246629",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246629",
              "zplace": "1",
              "shelfId": "SP0025"
            },
            {
              "id": "444170AA246630",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246630",
              "zplace": "1",
              "shelfId": "SP0026"
            },
            {
              "id": "444170AA246631",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246631",
              "zplace": "1",
              "shelfId": "SP0027"
            },
            {
              "id": "444170AA246632",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246632",
              "zplace": "1",
              "shelfId": "SP0028"
            },
            {
              "id": "444170AA246633",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246633",
              "zplace": "1",
              "shelfId": "SP0029"
            },
            {
              "id": "444170AA246634",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246634",
              "zplace": "1",
              "shelfId": "SP0030"
            },
            {
              "id": "444170AA246635",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246635",
              "zplace": "1",
              "shelfId": "SP0031"
            },
            {
              "id": "444170AA246636",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246636",
              "zplace": "1",
              "shelfId": "SP0032"
            },
            {
              "id": "444170AA246637",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246637",
              "zplace": "1",
              "shelfId": "SP0033"
            },
            {
              "id": "444170AA246638",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444170",
              "yplace": "246638",
              "zplace": "1",
              "shelfId": "SP0034"
            },
            {
              "id": "444145AA209290",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "209290",
              "zplace": "1",
              "shelfId": "SP0035"
            },
            {
              "id": "444145AA207740",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "207740",
              "zplace": "1",
              "shelfId": "SP0036"
            },
            {
              "id": "444145AA206090",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "206090",
              "zplace": "1",
              "shelfId": "SP0037"
            },
            {
              "id": "444145AA204340",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "204340",
              "zplace": "1",
              "shelfId": "SP0038"
            },
            {
              "id": "444145AA202685",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "202685",
              "zplace": "1",
              "shelfId": "SP0039"
            },
            {
              "id": "444145AA201065",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "201065",
              "zplace": "1",
              "shelfId": "SP0040"
            },
            {
              "id": "444145AA199210",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "199210",
              "zplace": "1",
              "shelfId": "SP0041"
            },
            {
              "id": "444145AA197520",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "197520",
              "zplace": "1",
              "shelfId": "SP0042"
            },
            {
              "id": "444145AA195865",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "195865",
              "zplace": "1",
              "shelfId": "SP0043"
            },
            {
              "id": "444145AA189940",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "189940",
              "zplace": "1",
              "shelfId": "SP0044"
            },
            {
              "id": "444145AA188090",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "188090",
              "zplace": "1",
              "shelfId": "SP0045"
            },
            {
              "id": "444145AA186240",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "186240",
              "zplace": "1",
              "shelfId": "SP0046"
            },
            {
              "id": "444145AA184385",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "184385",
              "zplace": "1",
              "shelfId": "SP0047"
            },
            {
              "id": "444145AA175680",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "175680",
              "zplace": "1",
              "shelfId": "SP0048"
            },
            {
              "id": "444145AA173565",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "173565",
              "zplace": "1",
              "shelfId": "SP0049"
            },
            {
              "id": "444145AA171775",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "171775",
              "zplace": "1",
              "shelfId": "SP0050"
            },
            {
              "id": "444145AA167815",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "167815",
              "zplace": "1",
              "shelfId": "SP0051"
            },
            {
              "id": "444145AA166065",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "166065",
              "zplace": "1",
              "shelfId": "SP0052"
            },
            {
              "id": "444145AA162460",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "162460",
              "zplace": "1",
              "shelfId": "SP0053"
            },
            {
              "id": "444145AA160920",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "160920",
              "zplace": "1",
              "shelfId": "SP0054"
            },
            {
              "id": "444145AA159370",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "159370",
              "zplace": "1",
              "shelfId": "SP0055"
            },
            {
              "id": "444145AA157715",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "157715",
              "zplace": "1",
              "shelfId": "SP0056"
            },
            {
              "id": "444145AA156165",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "156165",
              "zplace": "1",
              "shelfId": "SP0057"
            },
            {
              "id": "444145AA154610",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "154610",
              "zplace": "1",
              "shelfId": "SP0058"
            },
            {
              "id": "444145AA152965",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "152965",
              "zplace": "1",
              "shelfId": "SP0059"
            },
            {
              "id": "444145AA151235",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "151235",
              "zplace": "1",
              "shelfId": "SP0060"
            },
            {
              "id": "444145AA149635",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "149635",
              "zplace": "1",
              "shelfId": "SP0061"
            },
            {
              "id": "444145AA148040",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "444145",
              "yplace": "148040",
              "zplace": "1",
              "shelfId": "SP0062"
            },
            {
              "id": "443995AA164220",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "443995",
              "yplace": "164220",
              "zplace": "1",
              "shelfId": "SP0063"
            },
            {
              "id": "443985AA280995",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "443985",
              "yplace": "280995",
              "zplace": "1",
              "shelfId": "SP0064"
            },
            {
              "id": "443985AA279340",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "443985",
              "yplace": "279340",
              "zplace": "1",
              "shelfId": "SP0065"
            },
            {
              "id": "443985AA277690",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "443985",
              "yplace": "277690",
              "zplace": "1",
              "shelfId": "SP0066"
            },
            {
              "id": "443985AA261655",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "443985",
              "yplace": "261655",
              "zplace": "1",
              "shelfId": "SP0067"
            },
            {
              "id": "443795AA239030",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "443795",
              "yplace": "239030",
              "zplace": "1",
              "shelfId": "SP0068"
            },
            {
              "id": "443795AA237575",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "443795",
              "yplace": "237575",
              "zplace": "1",
              "shelfId": "SP0069"
            },
            {
              "id": "443795AA211040",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A001",
              "xplace": "443795",
              "yplace": "211040",
              "zplace": "1",
              "shelfId": "SP0070"
            }
          ]
        },
        {
          "id": "A002",
          "clrCenterNo": "001",
          "type": "1",
          "name": "存储二区",
          "status": 1,
          "floor": "1-1",
          "areaLength": "15",
          "areaWidth": "1",
          "x": "10",
          "y": "1",
          "z": "1",
          "storageLocationDTOS": [
            {
              "id": "443274AA191790",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443274",
              "yplace": "191790",
              "zplace": "1"
            },
            {
              "id": "443245AA292795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "292795",
              "zplace": "1"
            },
            {
              "id": "443245AA287905",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "287905",
              "zplace": "1"
            },
            {
              "id": "443245AA285650",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "285650",
              "zplace": "1"
            },
            {
              "id": "443245AA283995",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 2,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "283995",
              "zplace": "1"
            },
            {
              "id": "443245AA214990",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "214990",
              "zplace": "1"
            },
            {
              "id": "443245AA212690",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "212690",
              "zplace": "1"
            },
            {
              "id": "443245AA211040",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 2,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "211040",
              "zplace": "1"
            },
            {
              "id": "443245AA209290",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "209290",
              "zplace": "1"
            },
            {
              "id": "443245AA207740",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 3,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "207740",
              "zplace": "1"
            },
            {
              "id": "443245AA206090",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "206090",
              "zplace": "1"
            },
            {
              "id": "443245AA204340",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "204340",
              "zplace": "1"
            },
            {
              "id": "443245AA202685",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "202685",
              "zplace": "1"
            },
            {
              "id": "443245AA201065",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "201065",
              "zplace": "1"
            },
            {
              "id": "443245AA199210",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "199210",
              "zplace": "1"
            },
            {
              "id": "443245AA197520",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "197520",
              "zplace": "1"
            },
            {
              "id": "443245AA195865",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "195865",
              "zplace": "1"
            },
            {
              "id": "443245AA189940",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "189940",
              "zplace": "1"
            },
            {
              "id": "443245AA188090",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "188090",
              "zplace": "1"
            },
            {
              "id": "443245AA186240",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "186240",
              "zplace": "1"
            },
            {
              "id": "443245AA184385",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "184385",
              "zplace": "1"
            },
            {
              "id": "443245AA181555",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "181555",
              "zplace": "1"
            },
            {
              "id": "443245AA178385",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "178385",
              "zplace": "1"
            },
            {
              "id": "443245AA175680",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "175680",
              "zplace": "1"
            },
            {
              "id": "443245AA173565",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "173565",
              "zplace": "1"
            },
            {
              "id": "443245AA171775",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "171775",
              "zplace": "1"
            },
            {
              "id": "443245AA167815",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "167815",
              "zplace": "1"
            },
            {
              "id": "443245AA166065",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "166065",
              "zplace": "1"
            },
            {
              "id": "443245AA164220",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "164220",
              "zplace": "1"
            },
            {
              "id": "443245AA162460",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "162460",
              "zplace": "1"
            },
            {
              "id": "443245AA160920",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "160920",
              "zplace": "1"
            },
            {
              "id": "443245AA159370",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "159370",
              "zplace": "1"
            },
            {
              "id": "443245AA157715",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "157715",
              "zplace": "1"
            },
            {
              "id": "443245AA156165",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "156165",
              "zplace": "1"
            },
            {
              "id": "443245AA154610",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "154610",
              "zplace": "1"
            },
            {
              "id": "443245AA152965",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "152965",
              "zplace": "1"
            },
            {
              "id": "443245AA151235",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "151235",
              "zplace": "1"
            },
            {
              "id": "443245AA149635",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "149635",
              "zplace": "1"
            },
            {
              "id": "443245AA148040",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443245",
              "yplace": "148040",
              "zplace": "1"
            },
            {
              "id": "443243AA282524",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "282524",
              "zplace": "1"
            },
            {
              "id": "443243AA280995",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "280995",
              "zplace": "1"
            },
            {
              "id": "443243AA279340",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "279340",
              "zplace": "1"
            },
            {
              "id": "443243AA277690",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "277690",
              "zplace": "1"
            },
            {
              "id": "443243AA276040",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "276040",
              "zplace": "1"
            },
            {
              "id": "443243AA274190",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "274190",
              "zplace": "1"
            },
            {
              "id": "443243AA271745",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "271745",
              "zplace": "1"
            },
            {
              "id": "443243AA268935",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "268935",
              "zplace": "1"
            },
            {
              "id": "443243AA264080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "264080",
              "zplace": "1"
            },
            {
              "id": "443243AA261655",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "261655",
              "zplace": "1"
            },
            {
              "id": "443243AA259905",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "259905",
              "zplace": "1"
            },
            {
              "id": "443243AA258050",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "258050",
              "zplace": "1"
            },
            {
              "id": "443243AA256300",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "256300",
              "zplace": "1"
            },
            {
              "id": "443243AA254455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "254455",
              "zplace": "1"
            },
            {
              "id": "443243AA252705",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "252705",
              "zplace": "1"
            },
            {
              "id": "443243AA250955",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "250955",
              "zplace": "1"
            },
            {
              "id": "443243AA249100",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "249100",
              "zplace": "1"
            },
            {
              "id": "443243AA246605",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "246605",
              "zplace": "1"
            },
            {
              "id": "443243AA244100",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "244100",
              "zplace": "1"
            },
            {
              "id": "443243AA240485",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "240485",
              "zplace": "1"
            },
            {
              "id": "443243AA239030",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "239030",
              "zplace": "1"
            },
            {
              "id": "443243AA237575",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "237575",
              "zplace": "1"
            },
            {
              "id": "443243AA235825",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "235825",
              "zplace": "1"
            },
            {
              "id": "443243AA233675",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "233675",
              "zplace": "1"
            },
            {
              "id": "443243AA231920",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "231920",
              "zplace": "1"
            },
            {
              "id": "443243AA229770",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "229770",
              "zplace": "1"
            },
            {
              "id": "443243AA228015",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "228015",
              "zplace": "1"
            },
            {
              "id": "443243AA226265",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "226265",
              "zplace": "1"
            },
            {
              "id": "443243AA224415",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "224415",
              "zplace": "1"
            },
            {
              "id": "443243AA221910",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "221910",
              "zplace": "1"
            },
            {
              "id": "443243AA219410",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "443243",
              "yplace": "219410",
              "zplace": "1"
            },
            {
              "id": "442345AA301795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "301795",
              "zplace": "1"
            },
            {
              "id": "442345AA300795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "300795",
              "zplace": "1"
            },
            {
              "id": "442345AA299795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "299795",
              "zplace": "1"
            },
            {
              "id": "442345AA298795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "298795",
              "zplace": "1"
            },
            {
              "id": "442345AA297795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "297795",
              "zplace": "1"
            },
            {
              "id": "442345AA296795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "296795",
              "zplace": "1"
            },
            {
              "id": "442345AA295795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "295795",
              "zplace": "1"
            },
            {
              "id": "442345AA294795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "294795",
              "zplace": "1"
            },
            {
              "id": "442345AA293795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "293795",
              "zplace": "1"
            },
            {
              "id": "442345AA292795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "292795",
              "zplace": "1"
            },
            {
              "id": "442345AA291795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "291795",
              "zplace": "1"
            },
            {
              "id": "442345AA290795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "290795",
              "zplace": "1"
            },
            {
              "id": "442345AA289795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "289795",
              "zplace": "1"
            },
            {
              "id": "442345AA288795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "288795",
              "zplace": "1"
            },
            {
              "id": "442345AA287905",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "287905",
              "zplace": "1"
            },
            {
              "id": "442345AA287795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "287795",
              "zplace": "1"
            },
            {
              "id": "442345AA286795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "286795",
              "zplace": "1"
            },
            {
              "id": "442345AA285795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "285795",
              "zplace": "1"
            },
            {
              "id": "442345AA285650",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "285650",
              "zplace": "1"
            },
            {
              "id": "442345AA284795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "284795",
              "zplace": "1"
            },
            {
              "id": "442345AA283995",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "283995",
              "zplace": "1"
            },
            {
              "id": "442345AA283795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "283795",
              "zplace": "1"
            },
            {
              "id": "442345AA282795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "282795",
              "zplace": "1"
            },
            {
              "id": "442345AA282524",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "282524",
              "zplace": "1"
            },
            {
              "id": "442345AA281795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "281795",
              "zplace": "1"
            },
            {
              "id": "442345AA280995",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "280995",
              "zplace": "1"
            },
            {
              "id": "442345AA280795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "280795",
              "zplace": "1"
            },
            {
              "id": "442345AA279795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "279795",
              "zplace": "1"
            },
            {
              "id": "442345AA279340",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "279340",
              "zplace": "1"
            },
            {
              "id": "442345AA278795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "278795",
              "zplace": "1"
            },
            {
              "id": "442345AA277690",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "277690",
              "zplace": "1"
            },
            {
              "id": "442345AA276795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "276795",
              "zplace": "1"
            },
            {
              "id": "442345AA276040",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "276040",
              "zplace": "1"
            },
            {
              "id": "442345AA275795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "275795",
              "zplace": "1"
            },
            {
              "id": "442345AA274795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "274795",
              "zplace": "1"
            },
            {
              "id": "442345AA274190",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "274190",
              "zplace": "1"
            },
            {
              "id": "442345AA272895",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "272895",
              "zplace": "1"
            },
            {
              "id": "442345AA272295",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "272295",
              "zplace": "1"
            },
            {
              "id": "442345AA271745",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "271745",
              "zplace": "1"
            },
            {
              "id": "442345AA271480",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "271480",
              "zplace": "1"
            },
            {
              "id": "442345AA271080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "271080",
              "zplace": "1"
            },
            {
              "id": "442345AA270080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "270080",
              "zplace": "1"
            },
            {
              "id": "442345AA269080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "269080",
              "zplace": "1"
            },
            {
              "id": "442345AA268935",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "268935",
              "zplace": "1"
            },
            {
              "id": "442345AA268080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "268080",
              "zplace": "1"
            },
            {
              "id": "442345AA267080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "267080",
              "zplace": "1"
            },
            {
              "id": "442345AA266080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "266080",
              "zplace": "1"
            },
            {
              "id": "442345AA265080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "265080",
              "zplace": "1"
            },
            {
              "id": "442345AA264080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "264080",
              "zplace": "1"
            },
            {
              "id": "442345AA263105",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "263105",
              "zplace": "1"
            },
            {
              "id": "442345AA262080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "262080",
              "zplace": "1"
            },
            {
              "id": "442345AA261655",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "261655",
              "zplace": "1"
            },
            {
              "id": "442345AA261080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "261080",
              "zplace": "1"
            },
            {
              "id": "442345AA260080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "260080",
              "zplace": "1"
            },
            {
              "id": "442345AA259905",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "259905",
              "zplace": "1"
            },
            {
              "id": "442345AA259080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "259080",
              "zplace": "1"
            },
            {
              "id": "442345AA258050",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "258050",
              "zplace": "1"
            },
            {
              "id": "442345AA257080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "257080",
              "zplace": "1"
            },
            {
              "id": "442345AA256300",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "256300",
              "zplace": "1"
            },
            {
              "id": "442345AA256080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "256080",
              "zplace": "1"
            },
            {
              "id": "442345AA255080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "255080",
              "zplace": "1"
            },
            {
              "id": "442345AA254455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "254455",
              "zplace": "1"
            },
            {
              "id": "442345AA254080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "254080",
              "zplace": "1"
            },
            {
              "id": "442345AA253080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "253080",
              "zplace": "1"
            },
            {
              "id": "442345AA252705",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "252705",
              "zplace": "1"
            },
            {
              "id": "442345AA252080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "252080",
              "zplace": "1"
            },
            {
              "id": "442345AA251080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "251080",
              "zplace": "1"
            },
            {
              "id": "442345AA250955",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "250955",
              "zplace": "1"
            },
            {
              "id": "442345AA250080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "250080",
              "zplace": "1"
            },
            {
              "id": "442345AA249100",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "249100",
              "zplace": "1"
            },
            {
              "id": "442345AA248080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "248080",
              "zplace": "1"
            },
            {
              "id": "442345AA247080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "247080",
              "zplace": "1"
            },
            {
              "id": "442345AA246605",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "246605",
              "zplace": "1"
            },
            {
              "id": "442345AA246080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "246080",
              "zplace": "1"
            },
            {
              "id": "442345AA245080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "245080",
              "zplace": "1"
            },
            {
              "id": "442345AA244100",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "244100",
              "zplace": "1"
            },
            {
              "id": "442345AA243080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "243080",
              "zplace": "1"
            },
            {
              "id": "442345AA242080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "242080",
              "zplace": "1"
            },
            {
              "id": "442345AA241080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "241080",
              "zplace": "1"
            },
            {
              "id": "442345AA240485",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "240485",
              "zplace": "1"
            },
            {
              "id": "442345AA240245",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "240245",
              "zplace": "1"
            },
            {
              "id": "442345AA239030",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "239030",
              "zplace": "1"
            },
            {
              "id": "442345AA238645",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "238645",
              "zplace": "1"
            },
            {
              "id": "442345AA238045",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "238045",
              "zplace": "1"
            },
            {
              "id": "442345AA237575",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "237575",
              "zplace": "1"
            },
            {
              "id": "442345AA237045",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "237045",
              "zplace": "1"
            },
            {
              "id": "442345AA236045",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "236045",
              "zplace": "1"
            },
            {
              "id": "442345AA235825",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "235825",
              "zplace": "1"
            },
            {
              "id": "442345AA234745",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "234745",
              "zplace": "1"
            },
            {
              "id": "442345AA233675",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "233675",
              "zplace": "1"
            },
            {
              "id": "442345AA232745",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "232745",
              "zplace": "1"
            },
            {
              "id": "442345AA231920",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "231920",
              "zplace": "1"
            },
            {
              "id": "442345AA231745",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "231745",
              "zplace": "1"
            },
            {
              "id": "442345AA230440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "230440",
              "zplace": "1"
            },
            {
              "id": "442345AA229770",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "229770",
              "zplace": "1"
            },
            {
              "id": "442345AA229440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "229440",
              "zplace": "1"
            },
            {
              "id": "442345AA228440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "228440",
              "zplace": "1"
            },
            {
              "id": "442345AA228015",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "228015",
              "zplace": "1"
            },
            {
              "id": "442345AA227440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "227440",
              "zplace": "1"
            },
            {
              "id": "442345AA226440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "226440",
              "zplace": "1"
            },
            {
              "id": "442345AA226265",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "226265",
              "zplace": "1"
            },
            {
              "id": "442345AA225440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "225440",
              "zplace": "1"
            },
            {
              "id": "442345AA224415",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "224415",
              "zplace": "1"
            },
            {
              "id": "442345AA223440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "223440",
              "zplace": "1"
            },
            {
              "id": "442345AA221910",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "221910",
              "zplace": "1"
            },
            {
              "id": "442345AA221490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "221490",
              "zplace": "1"
            },
            {
              "id": "442345AA220490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "220490",
              "zplace": "1"
            },
            {
              "id": "442345AA219490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "219490",
              "zplace": "1"
            },
            {
              "id": "442345AA219410",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "219410",
              "zplace": "1"
            },
            {
              "id": "442345AA218490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "218490",
              "zplace": "1"
            },
            {
              "id": "442345AA217490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "217490",
              "zplace": "1"
            },
            {
              "id": "442345AA216490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "216490",
              "zplace": "1"
            },
            {
              "id": "442345AA215490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "215490",
              "zplace": "1"
            },
            {
              "id": "442345AA214990",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "214990",
              "zplace": "1"
            },
            {
              "id": "442345AA214490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "214490",
              "zplace": "1"
            },
            {
              "id": "442345AA213490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "213490",
              "zplace": "1"
            },
            {
              "id": "442345AA212690",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "212690",
              "zplace": "1"
            },
            {
              "id": "442345AA212490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "212490",
              "zplace": "1"
            },
            {
              "id": "442345AA211490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "211490",
              "zplace": "1"
            },
            {
              "id": "442345AA211040",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "211040",
              "zplace": "1"
            },
            {
              "id": "442345AA210490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "210490",
              "zplace": "1"
            },
            {
              "id": "442345AA209490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "209490",
              "zplace": "1"
            },
            {
              "id": "442345AA209290",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "209290",
              "zplace": "1"
            },
            {
              "id": "442345AA208490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "208490",
              "zplace": "1"
            },
            {
              "id": "442345AA207740",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "207740",
              "zplace": "1"
            },
            {
              "id": "442345AA207490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "207490",
              "zplace": "1"
            },
            {
              "id": "442345AA206310",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "206310",
              "zplace": "1"
            },
            {
              "id": "442345AA206090",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "206090",
              "zplace": "1"
            },
            {
              "id": "442345AA205490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "205490",
              "zplace": "1"
            },
            {
              "id": "442345AA204490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "204490",
              "zplace": "1"
            },
            {
              "id": "442345AA204340",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "204340",
              "zplace": "1"
            },
            {
              "id": "442345AA203410",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "203410",
              "zplace": "1"
            },
            {
              "id": "442345AA202685",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "202685",
              "zplace": "1"
            },
            {
              "id": "442345AA202490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "202490",
              "zplace": "1"
            },
            {
              "id": "442345AA201630",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "201630",
              "zplace": "1"
            },
            {
              "id": "442345AA201065",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "201065",
              "zplace": "1"
            },
            {
              "id": "442345AA200630",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "200630",
              "zplace": "1"
            },
            {
              "id": "442345AA199639",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "199639",
              "zplace": "1"
            },
            {
              "id": "442345AA199210",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "199210",
              "zplace": "1"
            },
            {
              "id": "442345AA198630",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "198630",
              "zplace": "1"
            },
            {
              "id": "442345AA197855",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "197855",
              "zplace": "1"
            },
            {
              "id": "442345AA197520",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "197520",
              "zplace": "1"
            },
            {
              "id": "442345AA196455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "196455",
              "zplace": "1"
            },
            {
              "id": "442345AA195865",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "195865",
              "zplace": "1"
            },
            {
              "id": "442345AA195455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "195455",
              "zplace": "1"
            },
            {
              "id": "442345AA194455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "194455",
              "zplace": "1"
            },
            {
              "id": "442345AA193455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "193455",
              "zplace": "1"
            },
            {
              "id": "442345AA192455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "192455",
              "zplace": "1"
            },
            {
              "id": "442345AA191790",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "191790",
              "zplace": "1"
            },
            {
              "id": "442345AA191455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "191455",
              "zplace": "1"
            },
            {
              "id": "442345AA190455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "190455",
              "zplace": "1"
            },
            {
              "id": "442345AA189940",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "189940",
              "zplace": "1"
            },
            {
              "id": "442345AA189455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "189455",
              "zplace": "1"
            },
            {
              "id": "442345AA188705",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "188705",
              "zplace": "1"
            },
            {
              "id": "442345AA188090",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "188090",
              "zplace": "1"
            },
            {
              "id": "442345AA187455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "187455",
              "zplace": "1"
            },
            {
              "id": "442345AA186240",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "186240",
              "zplace": "1"
            },
            {
              "id": "442345AA185455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "185455",
              "zplace": "1"
            },
            {
              "id": "442345AA184385",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "184385",
              "zplace": "1"
            },
            {
              "id": "442345AA183455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "183455",
              "zplace": "1"
            },
            {
              "id": "442345AA182455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "182455",
              "zplace": "1"
            },
            {
              "id": "442345AA181555",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "181555",
              "zplace": "1"
            },
            {
              "id": "442345AA181180",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "181180",
              "zplace": "1"
            },
            {
              "id": "442345AA180180",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "180180",
              "zplace": "1"
            },
            {
              "id": "442345AA179180",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "179180",
              "zplace": "1"
            },
            {
              "id": "442345AA178385",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "178385",
              "zplace": "1"
            },
            {
              "id": "442345AA178180",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "178180",
              "zplace": "1"
            },
            {
              "id": "442345AA177180",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "177180",
              "zplace": "1"
            },
            {
              "id": "442345AA176180",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "176180",
              "zplace": "1"
            },
            {
              "id": "442345AA175680",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "175680",
              "zplace": "1"
            },
            {
              "id": "442345AA175180",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "175180",
              "zplace": "1"
            },
            {
              "id": "442345AA174180",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "174180",
              "zplace": "1"
            },
            {
              "id": "442345AA173565",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "173565",
              "zplace": "1"
            },
            {
              "id": "442345AA173175",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "173175",
              "zplace": "1"
            },
            {
              "id": "442345AA171775",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "171775",
              "zplace": "1"
            },
            {
              "id": "442345AA171475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "171475",
              "zplace": "1"
            },
            {
              "id": "442345AA170475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "170475",
              "zplace": "1"
            },
            {
              "id": "442345AA169573",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "169573",
              "zplace": "1"
            },
            {
              "id": "442345AA168475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "168475",
              "zplace": "1"
            },
            {
              "id": "442345AA167815",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "167815",
              "zplace": "1"
            },
            {
              "id": "442345AA167475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "167475",
              "zplace": "1"
            },
            {
              "id": "442345AA166545",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "166545",
              "zplace": "1"
            },
            {
              "id": "442345AA166065",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "166065",
              "zplace": "1"
            },
            {
              "id": "442345AA165475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "165475",
              "zplace": "1"
            },
            {
              "id": "442345AA165195",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "165195",
              "zplace": "1"
            },
            {
              "id": "442345AA164220",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "164220",
              "zplace": "1"
            },
            {
              "id": "442345AA163845",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "163845",
              "zplace": "1"
            },
            {
              "id": "442345AA162460",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "162460",
              "zplace": "1"
            },
            {
              "id": "442345AA161475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "161475",
              "zplace": "1"
            },
            {
              "id": "442345AA160920",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "160920",
              "zplace": "1"
            },
            {
              "id": "442345AA160475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "160475",
              "zplace": "1"
            },
            {
              "id": "442345AA159475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "159475",
              "zplace": "1"
            },
            {
              "id": "442345AA159370",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "159370",
              "zplace": "1"
            },
            {
              "id": "442345AA158475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "158475",
              "zplace": "1"
            },
            {
              "id": "442345AA157715",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "157715",
              "zplace": "1"
            },
            {
              "id": "442345AA157475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "157475",
              "zplace": "1"
            },
            {
              "id": "442345AA156475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "156475",
              "zplace": "1"
            },
            {
              "id": "442345AA156165",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "156165",
              "zplace": "1"
            },
            {
              "id": "442345AA155475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "155475",
              "zplace": "1"
            },
            {
              "id": "442345AA154610",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "154610",
              "zplace": "1"
            },
            {
              "id": "442345AA153475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "153475",
              "zplace": "1"
            },
            {
              "id": "442345AA152965",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "152965",
              "zplace": "1"
            },
            {
              "id": "442345AA152475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "152475",
              "zplace": "1"
            },
            {
              "id": "442345AA151235",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "151235",
              "zplace": "1"
            },
            {
              "id": "442345AA150395",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "150395",
              "zplace": "1"
            },
            {
              "id": "442345AA149635",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "149635",
              "zplace": "1"
            },
            {
              "id": "442345AA149475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "149475",
              "zplace": "1"
            },
            {
              "id": "442345AA148040",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "148040",
              "zplace": "1"
            },
            {
              "id": "442345AA147775",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "442345",
              "yplace": "147775",
              "zplace": "1"
            },
            {
              "id": "440345AA301795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "301795",
              "zplace": "1"
            },
            {
              "id": "440345AA300795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "300795",
              "zplace": "1"
            },
            {
              "id": "440345AA299795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "299795",
              "zplace": "1"
            },
            {
              "id": "440345AA298795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "298795",
              "zplace": "1"
            },
            {
              "id": "440345AA297795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "297795",
              "zplace": "1"
            },
            {
              "id": "440345AA296795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "296795",
              "zplace": "1"
            },
            {
              "id": "440345AA295795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "295795",
              "zplace": "1"
            },
            {
              "id": "440345AA294795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "294795",
              "zplace": "1"
            },
            {
              "id": "440345AA293795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "293795",
              "zplace": "1"
            },
            {
              "id": "440345AA292795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "292795",
              "zplace": "1"
            },
            {
              "id": "440345AA291795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "291795",
              "zplace": "1"
            },
            {
              "id": "440345AA290795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "290795",
              "zplace": "1"
            },
            {
              "id": "440345AA289795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "289795",
              "zplace": "1"
            },
            {
              "id": "440345AA288795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "288795",
              "zplace": "1"
            },
            {
              "id": "440345AA287905",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "287905",
              "zplace": "1"
            },
            {
              "id": "440345AA286795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "286795",
              "zplace": "1"
            },
            {
              "id": "440345AA285795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "285795",
              "zplace": "1"
            },
            {
              "id": "440345AA284795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "284795",
              "zplace": "1"
            },
            {
              "id": "440345AA283795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "283795",
              "zplace": "1"
            },
            {
              "id": "440345AA282524",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "282524",
              "zplace": "1"
            },
            {
              "id": "440345AA281795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "281795",
              "zplace": "1"
            },
            {
              "id": "440345AA280995",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "280995",
              "zplace": "1"
            },
            {
              "id": "440345AA279340",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "279340",
              "zplace": "1"
            },
            {
              "id": "440345AA278795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "278795",
              "zplace": "1"
            },
            {
              "id": "440345AA277690",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "277690",
              "zplace": "1"
            },
            {
              "id": "440345AA277270",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "277270",
              "zplace": "1"
            },
            {
              "id": "440345AA276795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "276795",
              "zplace": "1"
            },
            {
              "id": "440345AA275795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "275795",
              "zplace": "1"
            },
            {
              "id": "440345AA274795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "274795",
              "zplace": "1"
            },
            {
              "id": "440345AA272895",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "272895",
              "zplace": "1"
            },
            {
              "id": "440345AA271945",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "271945",
              "zplace": "1"
            },
            {
              "id": "440345AA270945",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "270945",
              "zplace": "1"
            },
            {
              "id": "440345AA270080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "270080",
              "zplace": "1"
            },
            {
              "id": "440345AA269080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "269080",
              "zplace": "1"
            },
            {
              "id": "440345AA268080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "268080",
              "zplace": "1"
            },
            {
              "id": "440345AA267080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "267080",
              "zplace": "1"
            },
            {
              "id": "440345AA266080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "266080",
              "zplace": "1"
            },
            {
              "id": "440345AA265080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "265080",
              "zplace": "1"
            },
            {
              "id": "440345AA264080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "264080",
              "zplace": "1"
            },
            {
              "id": "440345AA263080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "263080",
              "zplace": "1"
            },
            {
              "id": "440345AA262080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "262080",
              "zplace": "1"
            },
            {
              "id": "440345AA261080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "261080",
              "zplace": "1"
            },
            {
              "id": "440345AA260080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "260080",
              "zplace": "1"
            },
            {
              "id": "440345AA259080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "259080",
              "zplace": "1"
            },
            {
              "id": "440345AA258080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "258080",
              "zplace": "1"
            },
            {
              "id": "440345AA257080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "257080",
              "zplace": "1"
            },
            {
              "id": "440345AA256080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "256080",
              "zplace": "1"
            },
            {
              "id": "440345AA255080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "255080",
              "zplace": "1"
            },
            {
              "id": "440345AA254080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "254080",
              "zplace": "1"
            },
            {
              "id": "440345AA253080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "253080",
              "zplace": "1"
            },
            {
              "id": "440345AA252080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "252080",
              "zplace": "1"
            },
            {
              "id": "440345AA251080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "251080",
              "zplace": "1"
            },
            {
              "id": "440345AA250080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "250080",
              "zplace": "1"
            },
            {
              "id": "440345AA249080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "249080",
              "zplace": "1"
            },
            {
              "id": "440345AA248080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "248080",
              "zplace": "1"
            },
            {
              "id": "440345AA247080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "247080",
              "zplace": "1"
            },
            {
              "id": "440345AA246080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "246080",
              "zplace": "1"
            },
            {
              "id": "440345AA245080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "245080",
              "zplace": "1"
            },
            {
              "id": "440345AA244080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "244080",
              "zplace": "1"
            },
            {
              "id": "440345AA243080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "243080",
              "zplace": "1"
            },
            {
              "id": "440345AA242080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "242080",
              "zplace": "1"
            },
            {
              "id": "440345AA241080",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "241080",
              "zplace": "1"
            },
            {
              "id": "440345AA240245",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "240245",
              "zplace": "1"
            },
            {
              "id": "440345AA238645",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "238645",
              "zplace": "1"
            },
            {
              "id": "440345AA238045",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "238045",
              "zplace": "1"
            },
            {
              "id": "440345AA237045",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "237045",
              "zplace": "1"
            },
            {
              "id": "440345AA235825",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "235825",
              "zplace": "1"
            },
            {
              "id": "440345AA234745",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "234745",
              "zplace": "1"
            },
            {
              "id": "440345AA233675",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "233675",
              "zplace": "1"
            },
            {
              "id": "440345AA232745",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "232745",
              "zplace": "1"
            },
            {
              "id": "440345AA231745",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "231745",
              "zplace": "1"
            },
            {
              "id": "440345AA229770",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "229770",
              "zplace": "1"
            },
            {
              "id": "440345AA229440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "229440",
              "zplace": "1"
            },
            {
              "id": "440345AA228440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "228440",
              "zplace": "1"
            },
            {
              "id": "440345AA227440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "227440",
              "zplace": "1"
            },
            {
              "id": "440345AA226265",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "226265",
              "zplace": "1"
            },
            {
              "id": "440345AA225440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "225440",
              "zplace": "1"
            },
            {
              "id": "440345AA224440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "224440",
              "zplace": "1"
            },
            {
              "id": "440345AA223440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "223440",
              "zplace": "1"
            },
            {
              "id": "440345AA221490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "221490",
              "zplace": "1"
            },
            {
              "id": "440345AA220490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "220490",
              "zplace": "1"
            },
            {
              "id": "440345AA219490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "219490",
              "zplace": "1"
            },
            {
              "id": "440345AA218490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "218490",
              "zplace": "1"
            },
            {
              "id": "440345AA217490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "217490",
              "zplace": "1"
            },
            {
              "id": "440345AA216490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "216490",
              "zplace": "1"
            },
            {
              "id": "440345AA215490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "215490",
              "zplace": "1"
            },
            {
              "id": "440345AA214990",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "214990",
              "zplace": "1"
            },
            {
              "id": "440345AA213490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "213490",
              "zplace": "1"
            },
            {
              "id": "440345AA212490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "212490",
              "zplace": "1"
            },
            {
              "id": "440345AA211040",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "211040",
              "zplace": "1"
            },
            {
              "id": "440345AA210490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "210490",
              "zplace": "1"
            },
            {
              "id": "440345AA209490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "209490",
              "zplace": "1"
            },
            {
              "id": "440345AA208490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "208490",
              "zplace": "1"
            },
            {
              "id": "440345AA207490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "207490",
              "zplace": "1"
            },
            {
              "id": "440345AA206310",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "206310",
              "zplace": "1"
            },
            {
              "id": "440345AA205490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "205490",
              "zplace": "1"
            },
            {
              "id": "440345AA204885",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "204885",
              "zplace": "1"
            },
            {
              "id": "440345AA204490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "204490",
              "zplace": "1"
            },
            {
              "id": "440345AA203410",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "203410",
              "zplace": "1"
            },
            {
              "id": "440345AA202490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "202490",
              "zplace": "1"
            },
            {
              "id": "440345AA201630",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "201630",
              "zplace": "1"
            },
            {
              "id": "440345AA201140",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "201140",
              "zplace": "1"
            },
            {
              "id": "440345AA200630",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "200630",
              "zplace": "1"
            },
            {
              "id": "440345AA199639",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "199639",
              "zplace": "1"
            },
            {
              "id": "440345AA198630",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "198630",
              "zplace": "1"
            },
            {
              "id": "440345AA197855",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "197855",
              "zplace": "1"
            },
            {
              "id": "440345AA196455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "196455",
              "zplace": "1"
            },
            {
              "id": "440345AA195455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "195455",
              "zplace": "1"
            },
            {
              "id": "440345AA194455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "194455",
              "zplace": "1"
            },
            {
              "id": "440345AA193455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "193455",
              "zplace": "1"
            },
            {
              "id": "440345AA192455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "192455",
              "zplace": "1"
            },
            {
              "id": "440345AA191455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "191455",
              "zplace": "1"
            },
            {
              "id": "440345AA190455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "190455",
              "zplace": "1"
            },
            {
              "id": "440345AA189455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "189455",
              "zplace": "1"
            },
            {
              "id": "440345AA188705",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "188705",
              "zplace": "1"
            },
            {
              "id": "440345AA188455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "188455",
              "zplace": "1"
            },
            {
              "id": "440345AA187455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "187455",
              "zplace": "1"
            },
            {
              "id": "440345AA186240",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "186240",
              "zplace": "1"
            },
            {
              "id": "440345AA185455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "185455",
              "zplace": "1"
            },
            {
              "id": "440345AA184385",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "184385",
              "zplace": "1"
            },
            {
              "id": "440345AA183455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "183455",
              "zplace": "1"
            },
            {
              "id": "440345AA182455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "182455",
              "zplace": "1"
            },
            {
              "id": "440345AA181555",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "181555",
              "zplace": "1"
            },
            {
              "id": "440345AA180180",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "180180",
              "zplace": "1"
            },
            {
              "id": "440345AA179180",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "179180",
              "zplace": "1"
            },
            {
              "id": "440345AA178385",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "178385",
              "zplace": "1"
            },
            {
              "id": "440345AA177180",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "177180",
              "zplace": "1"
            },
            {
              "id": "440345AA176180",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "176180",
              "zplace": "1"
            },
            {
              "id": "440345AA175680",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "175680",
              "zplace": "1"
            },
            {
              "id": "440345AA174180",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "174180",
              "zplace": "1"
            },
            {
              "id": "440345AA173175",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "173175",
              "zplace": "1"
            },
            {
              "id": "440345AA171475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "171475",
              "zplace": "1"
            },
            {
              "id": "440345AA170475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "170475",
              "zplace": "1"
            },
            {
              "id": "440345AA169573",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "169573",
              "zplace": "1"
            },
            {
              "id": "440345AA168475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "168475",
              "zplace": "1"
            },
            {
              "id": "440345AA167895",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "167895",
              "zplace": "1"
            },
            {
              "id": "440345AA167475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "167475",
              "zplace": "1"
            },
            {
              "id": "440345AA166545",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "166545",
              "zplace": "1"
            },
            {
              "id": "440345AA166065",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "166065",
              "zplace": "1"
            },
            {
              "id": "440345AA165195",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "165195",
              "zplace": "1"
            },
            {
              "id": "440345AA164220",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "164220",
              "zplace": "1"
            },
            {
              "id": "440345AA163845",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "163845",
              "zplace": "1"
            },
            {
              "id": "440345AA163475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "163475",
              "zplace": "1"
            },
            {
              "id": "440345AA162460",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "162460",
              "zplace": "1"
            },
            {
              "id": "440345AA160920",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "160920",
              "zplace": "1"
            },
            {
              "id": "440345AA160475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "160475",
              "zplace": "1"
            },
            {
              "id": "440345AA159370",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "159370",
              "zplace": "1"
            },
            {
              "id": "440345AA158475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "158475",
              "zplace": "1"
            },
            {
              "id": "440345AA157715",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "157715",
              "zplace": "1"
            },
            {
              "id": "440345AA156165",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "156165",
              "zplace": "1"
            },
            {
              "id": "440345AA155475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "155475",
              "zplace": "1"
            },
            {
              "id": "440345AA154610",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "154610",
              "zplace": "1"
            },
            {
              "id": "440345AA152965",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "152965",
              "zplace": "1"
            },
            {
              "id": "440345AA152475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "152475",
              "zplace": "1"
            },
            {
              "id": "440345AA151235",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "151235",
              "zplace": "1"
            },
            {
              "id": "440345AA150395",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "150395",
              "zplace": "1"
            },
            {
              "id": "440345AA149475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "149475",
              "zplace": "1"
            },
            {
              "id": "440345AA147775",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "440345",
              "yplace": "147775",
              "zplace": "1"
            },
            {
              "id": "439825AA240245",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439825",
              "yplace": "240245",
              "zplace": "1"
            },
            {
              "id": "439825AA238645",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439825",
              "yplace": "238645",
              "zplace": "1"
            },
            {
              "id": "439805AA223440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439805",
              "yplace": "223440",
              "zplace": "1"
            },
            {
              "id": "439805AA221490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439805",
              "yplace": "221490",
              "zplace": "1"
            },
            {
              "id": "439425AA272895",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439425",
              "yplace": "272895",
              "zplace": "1"
            },
            {
              "id": "439390AA197855",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439390",
              "yplace": "197855",
              "zplace": "1"
            },
            {
              "id": "439390AA196455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439390",
              "yplace": "196455",
              "zplace": "1"
            },
            {
              "id": "439385AA173175",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439385",
              "yplace": "173175",
              "zplace": "1"
            },
            {
              "id": "439385AA171475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439385",
              "yplace": "171475",
              "zplace": "1"
            },
            {
              "id": "439345AA274795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439345",
              "yplace": "274795",
              "zplace": "1"
            },
            {
              "id": "439345AA206310",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439345",
              "yplace": "206310",
              "zplace": "1"
            },
            {
              "id": "439345AA204885",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439345",
              "yplace": "204885",
              "zplace": "1"
            },
            {
              "id": "439345AA203410",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439345",
              "yplace": "203410",
              "zplace": "1"
            },
            {
              "id": "439345AA201140",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439345",
              "yplace": "201140",
              "zplace": "1"
            },
            {
              "id": "439345AA199639",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439345",
              "yplace": "199639",
              "zplace": "1"
            },
            {
              "id": "439345AA169573",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439345",
              "yplace": "169573",
              "zplace": "1"
            },
            {
              "id": "439345AA167895",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439345",
              "yplace": "167895",
              "zplace": "1"
            },
            {
              "id": "439345AA166545",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439345",
              "yplace": "166545",
              "zplace": "1"
            },
            {
              "id": "439345AA165195",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439345",
              "yplace": "165195",
              "zplace": "1"
            },
            {
              "id": "439345AA163845",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "439345",
              "yplace": "163845",
              "zplace": "1"
            },
            {
              "id": "438865AA149475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "438865",
              "yplace": "149475",
              "zplace": "1"
            },
            {
              "id": "438865AA147775",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "438865",
              "yplace": "147775",
              "zplace": "1"
            },
            {
              "id": "438825AA240245",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "438825",
              "yplace": "240245",
              "zplace": "1"
            },
            {
              "id": "438825AA238645",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "438825",
              "yplace": "238645",
              "zplace": "1"
            },
            {
              "id": "438805AA223440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "438805",
              "yplace": "223440",
              "zplace": "1"
            },
            {
              "id": "438805AA221490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A002",
              "xplace": "438805",
              "yplace": "221490",
              "zplace": "1"
            }
          ]
        },
        {
          "id": "A001",
          "clrCenterNo": "001",
          "type": "1",
          "name": "存储三区",
          "status": 1,
          "floor": "1-1",
          "areaLength": "17",
          "areaWidth": "1",
          "x": "26",
          "y": "1",
          "z": "1",
          "storageLocationDTOS": [
            {
              "id": "430890AA223440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "430890",
              "yplace": "223440",
              "zplace": "1"
            },
            {
              "id": "430890AA221490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "430890",
              "yplace": "221490",
              "zplace": "1"
            },
            {
              "id": "430825AA240245",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 2,
              "areaId": "A003",
              "xplace": "430825",
              "yplace": "240245",
              "zplace": "1"
            },
            {
              "id": "430825AA238645",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "430825",
              "yplace": "238645",
              "zplace": "1"
            },
            {
              "id": "430750AA149475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 2,
              "areaId": "A003",
              "xplace": "430750",
              "yplace": "149475",
              "zplace": "1"
            },
            {
              "id": "430750AA147775",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "430750",
              "yplace": "147775",
              "zplace": "1"
            },
            {
              "id": "430495AA274795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 3,
              "areaId": "A003",
              "xplace": "430495",
              "yplace": "274795",
              "zplace": "1"
            },
            {
              "id": "430495AA272895",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "430495",
              "yplace": "272895",
              "zplace": "1"
            },
            {
              "id": "430390AA197855",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "430390",
              "yplace": "197855",
              "zplace": "1"
            },
            {
              "id": "430390AA196455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "430390",
              "yplace": "196455",
              "zplace": "1"
            },
            {
              "id": "430385AA173175",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "430385",
              "yplace": "173175",
              "zplace": "1"
            },
            {
              "id": "430385AA171475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "430385",
              "yplace": "171475",
              "zplace": "1"
            },
            {
              "id": "430000AA302100",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "430000",
              "yplace": "302100",
              "zplace": "1"
            },
            {
              "id": "430000AA300000",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "430000",
              "yplace": "300000",
              "zplace": "1"
            },
            {
              "id": "429890AA223440",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "429890",
              "yplace": "223440",
              "zplace": "1"
            },
            {
              "id": "429890AA221490",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "429890",
              "yplace": "221490",
              "zplace": "1"
            },
            {
              "id": "429825AA240245",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "429825",
              "yplace": "240245",
              "zplace": "1"
            },
            {
              "id": "429825AA238645",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "429825",
              "yplace": "238645",
              "zplace": "1"
            },
            {
              "id": "429750AA149475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "429750",
              "yplace": "149475",
              "zplace": "1"
            },
            {
              "id": "429750AA147775",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "429750",
              "yplace": "147775",
              "zplace": "1"
            },
            {
              "id": "429495AA272895",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "429495",
              "yplace": "272895",
              "zplace": "1"
            },
            {
              "id": "429415AA274795",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "429415",
              "yplace": "274795",
              "zplace": "1"
            },
            {
              "id": "429390AA197855",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "429390",
              "yplace": "197855",
              "zplace": "1"
            },
            {
              "id": "429390AA196455",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "429390",
              "yplace": "196455",
              "zplace": "1"
            },
            {
              "id": "429385AA173175",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "429385",
              "yplace": "173175",
              "zplace": "1"
            },
            {
              "id": "429385AA171475",
              "clrCenterNo": "001",
              "locationType": 2,
              "status": 1,
              "areaId": "A003",
              "xplace": "429385",
              "yplace": "171475",
              "zplace": "1"
            }
          ]
        }
      ]
    });
  }

  /// 下发搬运指令
  Future<Map<String, dynamic>> qryLineByEscortNo(
      Map<String, dynamic> params) async {
    return _dioService
        .post('/storage/v2/workJob/launchCarry', body: <String, dynamic>{
      'operateType': params['operateType'], // 作业类型：location2location-库位到库位搬运
      'origCell': params['origCell'], // 起始库位
      'destCell': params['destCell'], // 终点库位
      'carryContainerType': params['carryContainerType'], // 搬运容器类型
      'carryContainerId': params['carryContainerId'] // 搬运容器编号
    });
  }

  /// 托盘管理查询
  /// 参数：
  /// shelfId - 托盘编号
  /// shelfType - 货架类型 0-固定货架 1-笼车 2-托盘 3-虚拟货架(侧推位,工作位,排队位,抱夹式AGV位置)
  /// status - 货架状态 0-禁用 1-空闲 2-锁定 3-占用 4 - 满载
  /// clrCenterNo - 所属仓库编号
  /// locationId - 所在地标ID
  /// note - 备注
  /// curPage - 当前页
  /// pageSize - 页面大小
  Future<Map<String, dynamic>> qryPageByParams(
      Map<String, dynamic> params) async {
    return _dioService.get('/storage/v2/shelf/qryPageByParams',
        queryParameters: <String, dynamic>{
          'shelfId': params['shelfId'],
          'shelfType': params['shelfType'],
          if (params['status'] is int) 'status': params['status'],
          'clrCenterNo': params['clrCenterNo'],
          'locationId': params['locationId'],
          'note': params['note'],
          'curPage': params['curPage'],
          'pageSize': params['pageSize']
        });
  }

  /// 新增托盘
  /// 参数：
  /// shelfId - 托盘编号
  /// shelfType - 货架类型 0-固定货架 1-笼车 2-托盘 3-虚拟货架(侧推位,工作位,排队位,抱夹式AGV位置)
  /// status - 货架状态 0-禁用 1-空闲 2-锁定 3-占用 4 - 满载
  /// clrCenterNo - 所属仓库编号
  /// locationId - 所在地标ID
  /// note - 备注
  Future<Map<String, dynamic>> addShelf(Map<String, dynamic> params) async {
    return _dioService.post('/storage/v2/shelf/addShelfInfo', body: params);
  }

  /// 修改托盘
  /// 参数：
  /// shelfId - 托盘编号
  /// shelfType - 货架类型 0-固定货架 1-笼车 2-托盘 3-虚拟货架(侧推位,工作位,排队位,抱夹式AGV位置)
  /// status - 货架状态 0-禁用 1-空闲 2-锁定 3-占用 4 - 满载
  /// clrCenterNo - 所属仓库编号
  /// locationId - 所在地标ID
  /// note - 备注
  ///
  Future<Map<String, dynamic>> updateShelf(Map<String, dynamic> params) async {
    return _dioService.post('/storage/v2/shelf/updateShelfInfo', body: params);
  }

  /// 地标管理查询
  /// 参数：
  /// id - 库区编号
  /// locationType - 地标类型 0-NULL(空) 1-FIXED_SHELF（固定货架) 2-MOVE_SHELF(移动货架) 3-虚拟库位(潜伏式AGV) 4-CHARGER(充电桩))
  /// status - 地标状态 0-禁用 1-空闲 2-锁定 3-占用
  /// areaId - 所属库区ID
  Future<Map<String, dynamic>> qryAllByParams(
      Map<String, dynamic> params) async {
    return _dioService.get('/storage/v2/location/qryAllByParams',
        queryParameters: params);
  }

  /// 分页地标管理查询
  /// 参数：
  /// id - 库区编号
  /// locationType - 地标类型 0-NULL(空) 1-FIXED_SHELF（固定货架) 2-MOVE_SHELF(移动货架) 3-虚拟库位(潜伏式AGV) 4-CHARGER(充电桩))
  /// status - 地标状态 0-禁用 1-空闲 2-锁定 3-占用
  /// areaId - 所属库区ID
  Future<Map<String, dynamic>> qryByPage(Map<String, dynamic> params) async {
    return _dioService.get('/storage/v2/location/qryByPage',
        queryParameters: params);
  }

  /// 库区查询
  /// 参数：
  /// id - 库区id
  /// name - 库区名称
  /// clrCenterNo - 所属仓库
  /// type - 库区类型：：1-存储库 2-暂存库 3-入库区 4-交接库
  /// status - 库区状态 0-禁用 1-启用
  Future<Map<String, dynamic>> qryAreaByParams(
      Map<String, dynamic> params) async {
    return _dioService.get('/storage/v2/area/qryAreaByParams',
        queryParameters: params);
  }

  /// 库区查询分页查询
  /// 参数：
  /// id - 库区id
  /// name - 库区名称
  /// clrCenterNo - 所属仓库
  /// type - 库区类型：：1-存储库 2-暂存库 3-入库区 4-交接库
  /// status - 库区状态 0-禁用 1-启用
  /// curPage - 当前页
  /// pageSize - 页面大小
  Future<Map<String, dynamic>> qryAreaPageByParams(
      Map<String, dynamic> params) async {
    return _dioService.get('/storage/v2/area/qryAreaPageByParams',
        queryParameters: params);
  }

  /// 库区新增
  /// 参数：
  /// id - 库区编号
  /// name - 库区名称
  /// type - 库区类型 1-存储库 2-暂存库 3-入库区 4-交接库（默认：1-存储区）
  /// clrCenterNo - 所属仓库（默认AA）
  /// status - 库区状态 0-禁用 1-启用（默认：1-启用）
  /// note - 备注
  /// floor - 楼层 1-1层 2-2层 3-3层
  /// areaLength - 库区长度
  /// areaWidth - 库区宽度
  /// x - x坐标
  /// y - y坐标
  /// z - z坐标
  Future<Map<String, dynamic>> addArea(Map<String, dynamic> params) async {
    return _dioService.post('/storage/v2/area/addArea', body: params);
  }

  /// 库区修改
  /// 参数：库区编号不可更改
  Future<Map<String, dynamic>> updateArea(Map<String, dynamic> params) async {
    return _dioService.post('/storage/v2/area/updateArea', body: params);
  }

  /// 库区删除
  /// 参数：库区编号
  Future<Map<String, dynamic>> deleteArea(List<String> areas) async {
    return _dioService.post('/storage/v2/area/deleteAreaByIds', body: areas);
  }

  /// 设备URL查询
  Future<Map<String, dynamic>> getAllUrlInfoList() async {
    return _dioService.get('/storage/v2/dev/getAllUrlInfoList');
  }

  /// 更新设备URL
  /// 参数：
  /// devId - 主键 001（不可修改，前端不用显示）
  /// devName - 系统名称
  /// devIp - ip
  /// devPort - 端口号
  Future<Map<String, dynamic>> updateDevInfo(
      Map<String, dynamic> params) async {
    return _dioService.post('/storage/v2/dev/updateDevInfo', body: params);
  }
}
