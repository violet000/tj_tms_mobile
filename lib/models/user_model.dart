class UserInfo {
  final String id;
  final String username;
  final String name;
  final String token;
  final List<String> roles;
  final List<String> permissions;

  UserInfo({
    required this.id,
    required this.username,
    required this.name,
    required this.token,
    required this.roles,
    required this.permissions,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      token: json['token'] as String,
      roles: List<String>.from(json['roles'] as List),
      permissions: List<String>.from(json['permissions'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'token': token,
      'roles': roles,
      'permissions': permissions,
    };
  }
} 