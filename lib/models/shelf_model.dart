class ShelfModel {
  final String shelfId; // 托盘编号
  final int shelfType; // 托盘类型
  final int status; // 托盘状态
  final String clrCenterNo; // 清分中心编号
  final String locationId; // 位置ID
  final String note; // 备注

  ShelfModel({
    required this.shelfId,
    required this.shelfType,
    required this.status,
    required this.clrCenterNo,
    required this.locationId,
    required this.note,
  });

  factory ShelfModel.fromJson(Map<String, dynamic> json) {
    return ShelfModel(
      shelfId: json['shelfId']?.toString() ?? '',
      shelfType: int.tryParse(json['shelfType']?.toString() ?? '0') ?? 0,
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      clrCenterNo: json['clrCenterNo']?.toString() ?? '',
      locationId: json['locationId']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'shelfId': shelfId,
      'shelfType': shelfType,
      'status': status,
      'clrCenterNo': clrCenterNo,
      'locationId': locationId,
    };
  }
}