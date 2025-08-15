class LandmarkModel {
  final String id; // 地标ID
  final String clrCenterNo; // 清分中心编号
  final int locationType; // 地点类型
  final int status; // 状态
  final String areaId; // 区域ID
  final String areaName; // 区域名称
  final String length; // 长度
  final String width; // 宽度
  final String xplace; // x坐标
  final String yplace; // y坐标
  final String zplace; // z坐标
  final String note; // 备注

  LandmarkModel({
    required this.id,
    required this.clrCenterNo,
    required this.locationType,
    required this.status,
    required this.areaId,
    required this.areaName,
    required this.length,
    required this.width,
    required this.xplace,
    required this.yplace,
    required this.zplace,
    required this.note,
  });

  factory LandmarkModel.fromJson(Map<String, dynamic> json) {
    return LandmarkModel(
      id: json['id']?.toString() ?? '',
      clrCenterNo: json['clrCenterNo']?.toString() ?? '',
      locationType: int.tryParse(json['locationType']?.toString() ?? '0') ?? 0,
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      areaId: json['areaId']?.toString() ?? '',
      areaName: json['areaName']?.toString() ?? '',
      length: json['length']?.toString() ?? '',
      width: json['width']?.toString() ?? '',
      xplace: json['xplace']?.toString() ?? '',
      yplace: json['yplace']?.toString() ?? '',
      zplace: json['zplace']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }
} 