class MenuItem {
  final String id;
  final String name;
  final String? icon;
  final String? route;
  final List<MenuItem>? children;
  final List<String>? permissions;

  MenuItem({
    required this.id,
    required this.name,
    this.icon,
    this.route,
    this.children,
    this.permissions,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      route: json['route'] as String?,
      children: json['children'] != null
          ? (json['children'] as List)
              .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      permissions: json['permissions'] != null
          ? (json['permissions'] as List).map((e) => e as String).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'route': route,
      'children': children?.map((e) => e.toJson()).toList(),
      'permissions': permissions,
    };
  }
} 