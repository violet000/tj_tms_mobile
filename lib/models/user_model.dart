class UserInfo {
  final String id;
  final String username;
  final String name;
  final String? avatar;
  final String token;
  final List<String> roles;
  final List<String> permissions;

  UserInfo({
    required this.id,
    required this.username,
    required this.name,
    this.avatar,
    required this.token,
    required this.roles,
    required this.permissions,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      token: json['token'] as String,
      roles: (json['roles'] as List).map((e) => e as String).toList(),
      permissions: (json['permissions'] as List).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'avatar': avatar,
      'token': token,
      'roles': roles,
      'permissions': permissions,
    };
  }
} 