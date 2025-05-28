// import 'package:flutter/foundation.dart';
// import 'package:tj_tms_mobile/data/datasources/interceptor/dio_service.dart';
// import 'package:tj_tms_mobile/models/user_model.dart';
// import 'package:tj_tms_mobile/models/menu_model.dart';

// class AuthProvider with ChangeNotifier {
//   final ApiService _api = ApiService(baseUrl: 'https://api.example.com');
  
//   bool _isLoading = false;
//   bool get isLoading => _isLoading;
  
//   String? _error;
//   String? get error => _error;
  
//   bool _isAccountVerified1 = false;
//   bool get isAccountVerified1 => _isAccountVerified1;
  
//   bool _isAccountVerified2 = false;
//   bool get isAccountVerified2 => _isAccountVerified2;

//   bool _isPhotoVerified1 = false;
//   bool get isPhotoVerified1 => _isPhotoVerified1;
  
//   bool _isPhotoVerified2 = false;
//   bool get isPhotoVerified2 => _isPhotoVerified2;
  
//   String? _username1;
//   String? get username1 => _username1;
  
//   String? _username2;
//   String? get username2 => _username2;

//   UserInfo? _userInfo;
//   List<MenuItem>? _menuItems;

//   // Getters
//   UserInfo? get userInfo => _userInfo;
//   List<MenuItem>? get menuItems => _menuItems;

//   // 清除第一个用户的账号验证状态
//   void clearAccountVerification1() {
//     _isAccountVerified1 = false;
//     _username1 = null;
//     notifyListeners();
//   }

//   // 清除第二个用户的账号验证状态
//   void clearAccountVerification2() {
//     _isAccountVerified2 = false;
//     _username2 = null;
//     notifyListeners();
//   }

//   // 账号登录
//   Future<bool> loginWithAccount({
//     required int userIndex,
//     required String username,
//     required String password,
//   }) async {
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();

//       print('Debug: 开始登录流程 - 用户索引: $userIndex, 用户名: $username');

//       // 模拟网络请求
//       await Future<void>.delayed(const Duration(seconds: 1));

//       // 更新验证状态
//       if (userIndex == 0) {
//         _username1 = username;
//         _isAccountVerified1 = true;
//         _isPhotoVerified1 = false; // 清除照片验证状态
//       } else {
//         _username2 = username;
//         _isAccountVerified2 = true;
//         _isPhotoVerified2 = false; // 清除照片验证状态
//       }

//       _isLoading = false;
//       notifyListeners(); // 确保在设置完所有数据后通知监听器
//       return true;
//     } catch (e) {
//       print('Debug: 登录过程中发生错误: $e');
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//       return false;
//     }
//   }

//   // 照片验证
//   Future<bool> verifyWithPhoto({
//     required int userIndex,
//     required String photoPath,
//   }) async {
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();

//       // 模拟网络请求
//       await Future<void>.delayed(const Duration(seconds: 1));

//       // 更新验证状态
//       if (userIndex == 0) {
//         _isAccountVerified1 = false; // 清除账号验证状态
//         _isPhotoVerified1 = true; // 设置照片验证状态
//       } else {
//         _isAccountVerified2 = false; // 清除账号验证状态
//         _isPhotoVerified2 = true; // 设置照片验证状态
//       }

//       _isLoading = false;
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//       return false;
//     }
//   }

//   // 提交验证
//   Future<bool> submitVerification() async {
//     try {
//       _isLoading = true;
//       _error = null;
//       notifyListeners();

//       // 模拟登录成功响应
//       final response = <String, dynamic>{
//         'id': '1',
//         'username': 'kychen',
//         'name': '陈开羽',
//         'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
//         'roles': <String>['user'],
//         'permissions': <String>['read', 'write', 'workbench:view', 'statistics:view', 'user:manage', 'role:manage'],
//         'menus': <Map<String, dynamic>>[
//           <String, dynamic>{
//             'id': 'menu1',
//             'name': '入库交接',
//             'icon': 'home',
//             'route': '/home',
//             'children': <Map<String, dynamic>>[
//               <String, dynamic>{
//                 'id': 'submenu1',
//                 'name': '红外扫码插件',
//                 'route': '/home/workbench',
//                 'permissions': <String>['workbench:view'],
//                 'icon': 'workbench',
//               },
//               <String, dynamic>{
//                 'id': 'submenu2',
//                 'name': 'AGPS定位',
//                 'route': '/home/statistics',
//                 'permissions': <String>['statistics:view'],
//                 'icon': 'statistics',
//               },
//             ],
//           },
//           <String, dynamic>{
//             'id': 'menu2',
//             'name': '出库交接',
//             'icon': 'settings',
//             'route': '/system',
//             'children': <Map<String, dynamic>>[
//               <String, dynamic>{
//                 'id': 'submenu3',
//                 'name': 'UHF扫码',
//                 'route': '/system/users',
//                 'permissions': <String>['user:manage'],
//                 'icon': 'user',
//               },
//               <String, dynamic>{
//                 'id': 'submenu4',
//                 'name': '金库出库交接',
//                 'route': '/system/roles',
//                 'permissions': <String>['role:manage'],
//                 'icon': 'role',
//               },
//             ],
//           },
//         ],
//       };

//       // 更新用户信息
//       _userInfo = UserInfo.fromJson(response);
      
//       // 更新菜单信息
//       final menuList = response['menus'] as List<dynamic>;
//       _menuItems = menuList.map<MenuItem>((dynamic e) {
//         return MenuItem.fromJson(e as Map<String, dynamic>);
//       }).toList();

//       _isLoading = false;
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _error = e.toString();
//       _isLoading = false;
//       notifyListeners();
//       return false;
//     }
//   }

//   // 检查权限
//   bool hasPermission(String permission) {
//     return _userInfo?.permissions.contains(permission) ?? false;
//   }

//   // 检查是否有菜单权限
//   bool hasMenuPermission(MenuItem menu) {
//     if (menu.permissions == null || menu.permissions!.isEmpty) {
//       return true;
//     }
//     return menu.permissions!.any((permission) => hasPermission(permission));
//   }

//   // 获取有权限的菜单
//   List<MenuItem> getAuthorizedMenus() {
//     if (_menuItems == null) return [];
    
//     final authorizedMenus = _menuItems!
//         .where((menu) => hasMenuPermission(menu))
//         .map((menu) {
//           if (menu.children == null) return menu;
          
//           final authorizedChildren = menu.children!
//               .where((child) => hasMenuPermission(child))
//               .toList();
          
//           return MenuItem(
//             id: menu.id,
//             name: menu.name,
//             icon: menu.icon,
//             route: menu.route,
//             permissions: menu.permissions,
//             children: authorizedChildren,
//           );
//         })
//         .toList();
    
//     return authorizedMenus;
//   }

//   // 重置状态
//   void reset() {
//     _isLoading = false;
//     _error = null;
//     _isAccountVerified1 = false;
//     _isAccountVerified2 = false;
//     _isPhotoVerified1 = false;
//     _isPhotoVerified2 = false;
//     _username1 = null;
//     _username2 = null;
//     _userInfo = null;
//     _menuItems = null; // 清除菜单数据
//     notifyListeners();
//   }
// } 