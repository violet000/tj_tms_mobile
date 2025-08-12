class User {
  final String userNo; // 用户编号
  final String userName; // 用户姓名
  final String numId; // 身份证号
  final String cocn; // 人脸base64
  final String avatar; // 头像
  final String phone; // 手机号
  final String role; // 角色

  User({
    required this.userNo,
    required this.userName,
    required this.numId,
    required this.cocn,
    required this.avatar,
    required this.phone,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userNo: json['userNo'] as String,
      userName: json['userName'] as String,
      numId: json['numId'] as String,
      cocn: json['cocn'] as String,
      avatar: json['avatar'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
    );
  }
}
