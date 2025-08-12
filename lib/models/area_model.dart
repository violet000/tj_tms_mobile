class AreaModel {
  final String id;
  final String name;
  final String type;
  final String clrCenterNo;
  final int status;
  final String note;
  final String floor;
  final String areaLength;
  final String areaWidth;
  final String x;
  final String y;
  final String z;

  AreaModel({
    required this.id,
    required this.name,
    required this.type,
    required this.clrCenterNo,
    required this.status,
    this.note = '',
    this.floor = '',
    this.areaLength = '',
    this.areaWidth = '',
    this.x = '',
    this.y = '',
    this.z = '',
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      clrCenterNo: json['clrCenterNo']?.toString() ?? '',
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      note: json['note']?.toString() ?? '',
      floor: json['floor']?.toString() ?? '',
      areaLength: json['areaLength']?.toString() ?? '',
      areaWidth: json['areaWidth']?.toString() ?? '',
      x: json['x']?.toString() ?? '',
      y: json['y']?.toString() ?? '',
      z: json['z']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type,
      'clrCenterNo': clrCenterNo,
      'status': status,
      'note': note,
      'floor': floor,
      'areaLength': areaLength,
      'areaWidth': areaWidth,
      'x': x,
      'y': y,
      'z': z,
    };
  }
}