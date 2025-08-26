import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:tj_tms_mobile/presentation/state/providers/verify_token_provider.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:flutter/services.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:tj_tms_mobile/core/utils/util.dart' as app_utils;

class PersonalCenterPage extends StatefulWidget {
  const PersonalCenterPage({super.key});

  @override
  State<PersonalCenterPage> createState() => _PersonalCenterPageState();
}

class _PersonalCenterPageState extends State<PersonalCenterPage> {
  List<Map<String, dynamic>> _allResponses = [];
  Map<String, dynamic> _deviceInfo = <String, dynamic>{};
  bool _isLoadingDeviceInfo = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final info = await app_utils.loadDeviceInfo();
    if (!mounted) return;
    setState(() {
      _deviceInfo = info;
      _isLoadingDeviceInfo = false;
    });
  }

  Future<void> _loadAllEscortsData() async {
    final responses = await getAllEscortsByNo();
    setState(() {
      _allResponses = responses;
    });
  }

  Future<List<Map<String, dynamic>>> getAllEscortsByNo() async {
    // 获取所有登录用户信息
    final verifyTokenProvider =
        Provider.of<VerifyTokenProvider>(context, listen: false);
    final allUsersData = verifyTokenProvider.getAllUsersData();

    EasyLoading.show(
      status: '刷新中...',
      maskType: EasyLoadingMaskType.black,
    );
    List<Map<String, dynamic>> allResponses = [];
    // 为每个用户获取押运员信息
    for (Map<String, dynamic> userData in allUsersData) {
      String userNo = userData['username']?.toString() ?? '';

      try {
        final service18082 = await Service18082.create();
        final Map<String, dynamic> response =
            await service18082.getEscortByNo(userNo);
        response['user_info'] = userData;
        allResponses.add(response);
      } catch (e) {
        AppLogger.error('获取用户 $userNo 的押运员信息失败: $e');
      }
    }
    EasyLoading.dismiss();
    return allResponses;
  }

  Future<Map<String, dynamic>> getEscortByNo() async {
    // 获取当前登录用户信息
    final verifyTokenProvider =
        Provider.of<VerifyTokenProvider>(context, listen: false);
    final userData = verifyTokenProvider.getUserData();
    String userNo = '';
    if (userData != null && userData['username'] != null) {
      userNo = userData['username'].toString();
    }

    final service18082 = await Service18082.create();
    final Map<String, dynamic> response =
        await service18082.getEscortByNo(userNo);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '个人中心',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部渐变信息区
            _buildTopProfile(context),
            const SizedBox(height: 5),
            // 功能区块
            ..._buildMenuList(context),
            const SizedBox(height: 20), // 替换 Spacer，添加固定间距
            // 设备信息展示
            _buildDeviceInfoSection(),
            const SizedBox(height: 20), // 底部间距
            // 退出登录按钮
            _buildLogoutButton(),
            const SizedBox(height: 10), // 底部间距
          ],
        ),
      ),
    );
  }


  Widget _buildTopProfile(BuildContext context) {
    return Stack(
      children: [
        // 渐变背景
        Container(
          height: 30,
        )
      ],
    );
  }

  List<Widget> _buildMenuList(BuildContext context) {
    // 获取所有登录用户信息
    final verifyTokenProvider =
        Provider.of<VerifyTokenProvider>(context, listen: false);
    final allUsersData = verifyTokenProvider.getAllUsersData();

    List<_MenuItemData> menuItems = [];

    // 为每个用户生成菜单项
    for (int i = 0; i < allUsersData.length; i++) {
      final userData = allUsersData[i];
      final username = userData['username']?.toString() ?? '未知用户';

      menuItems.add(_MenuItemData(
        icon: Icons.person,
        iconBg: _getUserColor(i),
        title: '押运员${i + 1}: $username',
        onTap: () {
          _showUserInfo(context, userData, i + 1);
        },
      ));
    }

    return menuItems
        .map((item) => Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14.0, vertical: 4), // 左右间距24，上下间距4
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8), // 左右间距10，上下间距10
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 54,
                      decoration: BoxDecoration(
                        color: item.iconBg.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(item.icon, size: 20, color: item.iconBg),
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.normal),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: item.onTap,
                  ),
                ),
              ),
            ))
        .toList();
  }

  // 根据用户索引获取不同的颜色
  Color _getUserColor(int index) {
    final colors = [
      const Color(0xFF2196F3), // 蓝色
      const Color(0xFF4CAF50), // 绿色
      const Color(0xFFFF9800), // 橙色
      const Color(0xFF9C27B0), // 紫色
      const Color(0xFFF44336), // 红色
    ];
    return colors[index % colors.length];
  }

  // 显示用户信息
  Future<void> _showUserInfo(
      BuildContext context, Map<String, dynamic> userData, int userIndex) async {

    // 显示加载状态
    EasyLoading.show(
      status: '信息查询中...',
      maskType: EasyLoadingMaskType.black,
    );

    try {
      // 获取单个用户的押运员信息
      final service18082 = await Service18082.create();
      final Map<String, dynamic> escortInfo = await service18082.getEscortByNo(userData['username']?.toString() ?? '');
      escortInfo['user_info'] = userData;

      EasyLoading.dismiss();

      // 在对话框内部维护可变数据，便于刷新时就地更新
      Map<String, dynamic> currentEscortInfo = escortInfo;

      showDialog<void>(
        context: context,
        barrierDismissible: false, // 防止点击外部关闭
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setState) {
              return Dialog(
                insetPadding: EdgeInsets.zero, // 移除默认边距
                backgroundColor: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero, // 移除圆角
                  ),
                  child: Column(
                    children: [
                  // 标题栏
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '押运员$userIndex 详细信息',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 内容区域
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14), // 左右间距20，上下间距24
                      child: Column(
                        children: [
                          // 头像和基本信息
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Column(
                              children: [
                                Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.blue.shade200, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: currentEscortInfo != null &&
                                            currentEscortInfo['cocn'] != null &&
                                            currentEscortInfo['cocn']
                                                .toString()
                                                .isNotEmpty
                                        ? Image.memory(
                                            base64Decode(
                                                currentEscortInfo['cocn'].toString()),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey.shade100,
                                                child: Icon(Icons.person,
                                                    size: 60,
                                                    color: Colors.grey.shade400),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey.shade100,
                                            child: Icon(Icons.person,
                                                size: 60,
                                                color: Colors.grey.shade400),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                            ),
                          ),

                          // 押运员信息卡片
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                if (currentEscortInfo != null) ...[
                                  _buildInfoRow('押运员姓名',
                                      currentEscortInfo['userName']?.toString() ?? '未知'),
                                  _buildInfoRow('押运员编号',
                                      currentEscortInfo['userNo']?.toString() ?? '未知'),
                                  _buildInfoRow('身份证编号',
                                      currentEscortInfo['numId']?.toString() ?? '未知'),
                                  _buildInfoRow('手机号码 ',
                                      currentEscortInfo['phone']?.toString() ?? '未知'),
                                ] else ...[
                                  _buildInfoRow('押运员姓名', '暂无数据'),
                                  _buildInfoRow('押运员编号', '暂无数据'),
                                  _buildInfoRow('身份证编号', '暂无数据'),
                                  _buildInfoRow('手机号码 ', '暂无数据'),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 底部按钮
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                EasyLoading.show(
                                  status: '刷新中...',
                                  maskType: EasyLoadingMaskType.black,
                                );
                                // 重新获取当前用户的押运员数据，直接更新当前弹框的状态
                                final service18082 = await Service18082.create();
                                final Map<String, dynamic> updatedEscortInfo = await service18082.getEscortByNo(userData['username']?.toString() ?? '');
                                updatedEscortInfo['user_info'] = userData;
                                EasyLoading.dismiss();

                                setState(() {
                                  currentEscortInfo = updatedEscortInfo;
                                });
                              } catch (e) {
                                EasyLoading.dismiss();
                                // 显示错误提示
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('刷新失败: $e'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.grey.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '刷新',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _showChangePasswordDialog(context, userData);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 227, 5, 5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              '修改密码',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      EasyLoading.dismiss();
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('获取用户信息失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 12), // 左右间距16，上下间距12
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 显示修改密码弹框
  void _showChangePasswordDialog(
      BuildContext context, Map<String, dynamic> userData) {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final username = userData['username']?.toString() ?? '';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // 为了实现就地刷新与实时校验，使用StatefulBuilder维护局部状态
        String? oldPwdError;
        String? newPwdError;
        String? confirmPwdError;

        void recalcErrors(void Function(void Function()) setState) {
          final oldPwd = oldPasswordController.text.trim();
          final newPwd = newPasswordController.text.trim();
          final confirmPwd = confirmPasswordController.text.trim();

          setState(() {
            oldPwdError = oldPwd.isEmpty ? '旧密码不能为空' : null;
            newPwdError = newPwd.isEmpty ? '新密码不能为空' : null;
            confirmPwdError = confirmPwd.isEmpty ? '请再次输入新密码' : null;

            // 交叉校验：仅当两者都不为空时检查一致性
            if ((newPwdError == null && confirmPwdError == null) && newPwd != confirmPwd) {
              confirmPwdError = '两次输入的新密码不一致';
            }
          });
        }

        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          backgroundColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setState) {
              return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '修改密码',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // 分隔线
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),

                // 内容区域
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 旧密码输入框
                      _buildPasswordInputField(
                        controller: oldPasswordController,
                        label: '旧密码',
                        hint: '请输入当前密码',
                        icon: Icons.lock_outline,
                        errorText: oldPwdError,
                        onChanged: (_) => recalcErrors(setState),
                      ),

                      const SizedBox(height: 16),

                      // 新密码输入框
                      _buildPasswordInputField(
                        controller: newPasswordController,
                        label: '新密码',
                        hint: '请输入新密码',
                        icon: Icons.lock_outline,
                        errorText: newPwdError,
                        onChanged: (_) => recalcErrors(setState),
                      ),

                      const SizedBox(height: 16),

                      // 确认密码输入框
                      _buildPasswordInputField(
                        controller: confirmPasswordController,
                        label: '确认密码',
                        hint: '请再次输入新密码',
                        icon: Icons.lock_outline,
                        errorText: confirmPwdError,
                        onChanged: (_) => recalcErrors(setState),
                      ),
                    ],
                  ),
                ),

                // 底部按钮
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '取消',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // 提交前校验，错误显示在输入框下方
                            recalcErrors(setState);
                            if (oldPwdError != null || newPwdError != null || confirmPwdError != null) {
                              return;
                            }
                            _handleChangePassword(
                              context,
                              userData,
                              oldPasswordController.text,
                              newPasswordController.text,
                              confirmPasswordController.text,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            '确认修改',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
              );
            },
          ),
        );
      },
    );
  }

  // 构建密码输入框
  Widget _buildPasswordInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return _PasswordInputField(
      controller: controller,
      label: label,
      hint: hint,
      icon: icon,
      errorText: errorText,
      onChanged: onChanged,
    );
  }

  // 处理修改密码
  Future<void> _handleChangePassword(
    BuildContext context,
    Map<String, dynamic> userData,
    String oldPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    // 验证输入
    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写所有密码字段'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('新密码与确认密码不一致'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final service18082 = await Service18082.create();
      await service18082.resetPassword(
          md5.convert(utf8.encode(newPassword + 'messi')).toString(),
          md5.convert(utf8.encode(oldPassword + 'messi')).toString());

      if (mounted) {
        Navigator.of(context).pop(); // 关闭弹框
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('密码修改成功'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('修改密码失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('修改密码失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18), // 底部留白
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 225, 20, 20),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: () {
          SystemNavigator.pop(); // 退出APP
        },
        child: const Text('退出登录',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildDeviceInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '设备信息',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoadingDeviceInfo)
                const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_deviceInfo.isEmpty)
                Text(
                  '无法获取设备信息',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                )
              else
                ..._buildDeviceInfoItems(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDeviceInfoItems() {
    final List<Widget> items = [];
    
    if (Platform.isAndroid) {
      items.addAll([
        _buildInfoItem('设备型号', (_deviceInfo['model'] as String?) ?? '未知'),
        _buildInfoItem('制造商', (_deviceInfo['manufacturer'] as String?) ?? '未知'),
        _buildInfoItem('Android版本', (_deviceInfo['version'] as String?) ?? '未知'),
        _buildInfoItem('SDK版本', '${_deviceInfo['sdkInt'] ?? '未知'}'),
        _buildInfoItem('设备ID', (_deviceInfo['deviceId'] as String?) ?? '未知'),
      ]);
    } else if (Platform.isIOS) {
      items.addAll([
        _buildInfoItem('设备名称', (_deviceInfo['name'] as String?) ?? '未知'),
        _buildInfoItem('设备型号', (_deviceInfo['model'] as String?) ?? '未知'),
        _buildInfoItem('系统版本', (_deviceInfo['systemVersion'] as String?) ?? '未知'),
        _buildInfoItem('设备ID', (_deviceInfo['deviceId'] as String?) ?? '未知'),
      ]);
    }
    
    return items;
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final Color iconBg;
  final String title;
  final VoidCallback onTap;
  const _MenuItemData(
      {required this.icon,
      required this.iconBg,
      required this.title,
      required this.onTap});
}

class _PasswordInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _PasswordInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.errorText,
    this.onChanged,
  });

  @override
  State<_PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<_PasswordInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            color: Color.fromARGB(255, 124, 123, 123),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (widget.errorText != null && widget.errorText!.isNotEmpty)
                  ? Colors.red.shade400
                  : Colors.grey.shade300,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: _obscureText,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: Color.fromARGB(255, 197, 196, 196), fontSize: 14),
              prefixIcon:
                  Icon(widget.icon, color: const Color.fromARGB(255, 180, 179, 179), size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: const Color.fromARGB(255, 207, 206, 206),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(fontSize: 16),
            onChanged: widget.onChanged,
          ),
        ),
        if (widget.errorText != null && widget.errorText!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: TextStyle(fontSize: 12, color: Colors.red.shade600),
          ),
        ],
      ],
    );
  }
}

