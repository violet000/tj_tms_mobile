class MenuItem {
  final String id;
  final String name;
  final String icon;
  final String route;
  final List<String>? permissions;
  final List<MenuItem>? children;

  MenuItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.route,
    this.permissions,
    this.children,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      route: json['route'] as String,
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'] as List)
          : null,
      children: json['children'] != null
          ? List<MenuItem>.from(
              (json['children'] as List).map(
                (x) => MenuItem.fromJson(x as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'route': route,
      'permissions': permissions,
      'children': children?.map((x) => x.toJson()).toList(),
    };
  }
} 