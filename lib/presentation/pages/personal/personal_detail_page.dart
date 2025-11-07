import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:tj_tms_mobile/presentation/pages/personal/personal_feild_input.dart';

class PersonalDetailPage extends StatefulWidget {
  const PersonalDetailPage({super.key});

  @override
  State<PersonalDetailPage> createState() => _PersonalDetailPageState();
}

class _PersonalDetailPageState extends State<PersonalDetailPage> {
  List<Map<String, dynamic>> _allResponses = [];
  Map<String, dynamic> _deviceInfo = <String, dynamic>{};
  bool _isChangingPassword = false;
  DateTime? _lastChangePwdTapAt;
  Map<String, dynamic> currentEscortInfo = <String, dynamic>{};
  Map<String, dynamic> userData = <String, dynamic>{};
  int userIndex = 0;
  bool _didInitRouteArgs = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitRouteArgs) return;
    final route = ModalRoute.of(context);
    if (route != null) {
      final args = route.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        userData = (args['userData'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        userIndex = (args['userIndex'] as int?) ?? 0;
        _showUserInfo(userData, userIndex);
      }
    }
    _didInitRouteArgs = true;
  }

  // 显示用户信息
  Future<void> _showUserInfo(Map<String, dynamic> userData, int userIndex) async {
    // 显示加载状态
    EasyLoading.show(
      status: '信息查询中...',
      maskType: EasyLoadingMaskType.black,
    );

    try {
      // 获取单个用户的押运员信息
      final service18082 = await Service18082.create();
      final Map<String, dynamic> escortInfo = await service18082
          .getEscortByNo(userData['username']?.toString() ?? '');
      escortInfo['user_info'] = userData;
      setState(() {
        currentEscortInfo = escortInfo;
      });
      EasyLoading.dismiss();
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
            if ((newPwdError == null && confirmPwdError == null) &&
                newPwd != confirmPwd) {
              confirmPwdError = '两次输入的新密码不一致';
            }
          });
        }

        bool isFormValid() {
          final oldPwd = oldPasswordController.text.trim();
          final newPwd = newPasswordController.text.trim();
          final confirmPwd = confirmPasswordController.text.trim();
          if (oldPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty)
            return false;
          if (newPwd != confirmPwd) return false;
          return true;
        }

        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Stack(
                children: [
                  // 半透明背景
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                  // 弹框内容
                  Positioned(
                    left: 20,
                    right: 20,
                    top: MediaQuery.of(context).viewInsets.bottom > 0
                        ? 20
                        : MediaQuery.of(context).size.height * 0.1,
                    child: StatefulBuilder(
                      builder: (BuildContext context,
                          void Function(void Function()) setState) {
                        return SingleChildScrollView(
                          child: Container(
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 20),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
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
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 12, 20, 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 旧密码输入框
                                      _buildPasswordInputField(
                                        controller: oldPasswordController,
                                        label: '旧密码',
                                        hint: '请输入当前密码',
                                        icon: Icons.lock_outline,
                                        errorText: oldPwdError,
                                        onChanged: (_) =>
                                            recalcErrors(setState),
                                      ),

                                      const SizedBox(height: 12),

                                      // 新密码输入框
                                      _buildPasswordInputField(
                                        controller: newPasswordController,
                                        label: '新密码',
                                        hint: '请输入新密码',
                                        icon: Icons.lock_outline,
                                        errorText: newPwdError,
                                        onChanged: (_) =>
                                            recalcErrors(setState),
                                      ),

                                      const SizedBox(height: 12),

                                      // 确认密码输入框
                                      _buildPasswordInputField(
                                        controller: confirmPasswordController,
                                        label: '确认密码',
                                        hint: '请再次输入新密码',
                                        icon: Icons.lock_outline,
                                        errorText: confirmPwdError,
                                        onChanged: (_) =>
                                            recalcErrors(setState),
                                      ),
                                    ],
                                  ),
                                ),

                                // 底部按钮
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.grey.shade100,
                                            foregroundColor:
                                                Colors.grey.shade700,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Text(
                                            '取消',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: (isFormValid() &&
                                                  !_isChangingPassword)
                                              ? () async {
                                                  // 1s 节流
                                                  final now = DateTime.now();
                                                  if (_lastChangePwdTapAt !=
                                                          null &&
                                                      now
                                                              .difference(
                                                                  _lastChangePwdTapAt!)
                                                              .inMilliseconds <
                                                          1000) {
                                                    return;
                                                  }
                                                  _lastChangePwdTapAt = now;

                                                  // 提交前校验，错误显示在输入框下方
                                                  recalcErrors(setState);
                                                  if (oldPwdError != null ||
                                                      newPwdError != null ||
                                                      confirmPwdError != null) {
                                                    return;
                                                  }

                                                  setState(() {
                                                    _isChangingPassword = true;
                                                  });
                                                  try {
                                                    await _handleChangePassword(
                                                      context,
                                                      userData,
                                                      oldPasswordController
                                                          .text,
                                                      newPasswordController
                                                          .text,
                                                      confirmPasswordController
                                                          .text,
                                                    );
                                                  } finally {
                                                    if (mounted) {
                                                      setState(() {
                                                        _isChangingPassword =
                                                            false;
                                                      });
                                                    }
                                                  }
                                                }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: (isFormValid() &&
                                                    !_isChangingPassword)
                                                ? Colors.blue
                                                : Colors.blue,
                                            foregroundColor: (isFormValid() &&
                                                    !_isChangingPassword)
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 2,
                                          ),
                                          child: _isChangingPassword
                                              ? const SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  ),
                                                )
                                              : const Text(
                                                  '确认修改',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500),
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
                    ),
                  ),
                ],
              ),
            ),
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
    return PasswordInputField(
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
    try {
      final service18082 = await Service18082.create();
      await service18082.resetPassword(
          userData['username']?.toString() ?? '',
          md5.convert(utf8.encode(newPassword + 'messi')).toString(),
          md5.convert(utf8.encode(oldPassword + 'messi')).toString());

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('密码修改成功'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
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

  // 构建信息卡片
  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 12),
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

  // 显示放大头像对话框
  void _showAvatarDialog() {
    if (currentEscortInfo == null ||
        currentEscortInfo['cocn'] == null ||
        currentEscortInfo['cocn'].toString().isEmpty) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.memory(
                    base64Decode(currentEscortInfo['cocn'].toString()),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 300,
                        height: 300,
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '押运员${userIndex} 详细信息',
      showBackButton: true,
      onBackPressed: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          arguments: {
            'selectedTab': 1,
          },
          (route) => false,
        );
      },
      child: Column(
        children: [
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
                        GestureDetector(
                          onTap: () {
                            _showAvatarDialog();
                          },
                          child: Container(
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
                                      errorBuilder: (context, error, stackTrace) {
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
                                          size: 60, color: Colors.grey.shade400),
                                    ),
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
                          _buildInfoRow(
                              '押运员姓名',
                              currentEscortInfo['userName']?.toString() ??
                                  '未知'),
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
                        final Map<String, dynamic> updatedEscortInfo =
                            await service18082.getEscortByNo(
                                userData['username']?.toString() ?? '');
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                      backgroundColor: const Color.fromARGB(255, 227, 5, 5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      '修改密码',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
