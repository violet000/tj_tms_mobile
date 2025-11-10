import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/core/constants/constant.dart';
import 'package:tj_tms_mobile/presentation/state/providers/face_login_provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/custom_text_field.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/face_scan_widget.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/uhf_plugin_widget.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/uhf_scan_button.dart';
// UHFController 类型已通过 uhf_plugin_widget.dart 导入
import 'package:image_picker/image_picker.dart';
import 'package:tj_tms_mobile/core/utils/util.dart' as app_utils;
import 'package:tj_tms_mobile/data/datasources/api/api.dart';
import 'package:tj_tms_mobile/core/utils/util.dart';
import 'package:tj_tms_mobile/presentation/state/providers/line_info_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:convert';
import 'dart:async';

/// 认证步骤枚举
enum AuthStep {
  login, // 登录步骤
  vehicleVerify, // 车辆核验步骤
  confirmVerify, // 人车核验确认步骤
}

/// 认证结果
class AuthResult {
  final bool success;
  final String? errorMessage;
  final String? username;
  final String? password;
  final String? faceImage;
  final String? vehicleRfid;
  final String? personRfid;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.username,
    this.password,
    this.faceImage,
    this.vehicleRfid,
    this.personRfid,
  });
}

/// 认证弹框控件
class AuthDialog extends StatefulWidget {
  final String? title;
  final String? vehicleRfidExpected; // 预期的车辆RFID
  final String? personRfidExpected; // 预期的人员RFID
  final VoidCallback? onCancel;
  final Function(AuthResult)? onComplete;

  const AuthDialog({
    Key? key,
    this.title,
    this.vehicleRfidExpected,
    this.personRfidExpected,
    this.onCancel,
    this.onComplete,
  }) : super(key: key);

  /// 显示认证弹框
  static Future<AuthResult?> show({
    required BuildContext context,
    String? title,
    String? vehicleRfidExpected,
    String? personRfidExpected,
    VoidCallback? onCancel,
    Function(AuthResult)? onComplete,
  }) {
    return showDialog<AuthResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AuthDialog(
        title: title,
        vehicleRfidExpected: vehicleRfidExpected,
        personRfidExpected: personRfidExpected,
        onCancel: onCancel,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  late PageController _pageController;

  AuthStep _currentStep = AuthStep.login;

  // 登录相关 - 单个人员
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _username = null;
  final _picker = ImagePicker();
  String? _faceImageBase64;

  // 登录方式状态 - 是否使用密码登录
  bool _usePassword = false;

  // 车辆核验相关
  String? _scannedVehicleRfid;
  String? _vehiclePlateNumber; // 车牌号
  bool _isVehicleScanning = false;
  UHFController? _vehicleScanController; // 车辆扫描控制器

  // 人员核验相关
  String? _scannedPersonRfid;
  bool _isPersonScanning = false;

  // 状态管理
  bool _isLoading = false;
  String? _selectedMismatchReason;

  // API服务相关
  Service18082? _loginService;
  Map<String, dynamic> _deviceInfo = <String, dynamic>{};
  static const List<String> _mismatchReasons = <String>[
    '押运员身份信息不一致',
    '押运车辆信息不一致',
    '其他原因'
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeLoginService();
    _loadDeviceInfo();

    // 为输入框添加监听器，实时更新按钮状态
    _usernameController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
  }

  /// 输入框内容变化时的回调
  void _onInputChanged() {
    setState(() {});
  }

  /// 初始化登录服务
  Future<void> _initializeLoginService() async {
    _loginService = await Service18082.create();
  }

  /// 加载设备信息
  Future<void> _loadDeviceInfo() async {
    final Map<String, dynamic> info = await app_utils.loadDeviceInfo();
    if (!mounted) return;
    setState(() {
      _deviceInfo = info;
    });
  }

  /// 根据原定与实际的比对结果返回颜色
  /// 规则：
  /// - 实际为空：灰色
  /// - 原定为空：绿色（视为不限制）
  /// - 二者一致：绿色
  /// - 二者不一致：红色
  Color _comparisonColor(String? expected, String? actual) {
    final String expectedTrimmed = (expected ?? '').trim();
    final String actualTrimmed = (actual ?? '').trim();
    if (actualTrimmed.isEmpty) {
      return Colors.red[700]!;
    }
    if (expectedTrimmed.isEmpty) {
      return Colors.red[700]!;
    }
    // 完全相等：一致
    if (expectedTrimmed == actualTrimmed) {
      return Colors.green[700]!;
    }

    // 允许 expected 为多值（以 / 分隔），当 actual 的每一项均包含在 expected 集合中时也判为一致
    final List<String> expectedParts = expectedTrimmed
        .split('/')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final List<String> actualParts = actualTrimmed
        .split('/')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (expectedParts.isNotEmpty && actualParts.isNotEmpty) {
      final Set<String> expectedSet = Set<String>.from(expectedParts);
      final bool allActualInExpected = actualParts.every(expectedSet.contains);
      if (allActualInExpected) {
        return Colors.green[700]!;
      }
    }

    return Colors.red[700]!;
  }

  Color _badgeBackground(Color base) {
    if (base == Colors.red[700]) return Colors.red[50]!;
    if (base == Colors.green[700]) return Colors.green[50]!;
    return Colors.grey[100]!;
  }

  String _middleEllipsis(String? value, {int head = 4, int tail = 4}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return '';
    if (text.length <= head + tail + 3) return text;
    return '${text.substring(0, head)}...${text.substring(text.length - tail)}';
  }

  void _showFullText(String title, String? content) {
    final text = (content ?? '').trim();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        content: SelectableText(text.isNotEmpty ? text : '无',
            style: const TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _vehicleScanController = null; // 清理 controller 引用
    super.dispose();
  }

  /// 切换到下一步
  void _nextStep() {
    switch (_currentStep) {
      case AuthStep.login:
        if (_validateLoginStep()) {
          _performLogin();
        }
        break;
      case AuthStep.vehicleVerify:
        if (_validateVehicleStep()) {
          setState(() {
            _currentStep = AuthStep.confirmVerify;
          });
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        break;
      case AuthStep.confirmVerify:
        _completeAuth();
        break;
    }
  }

  /// 执行登录操作
  Future<void> _performLogin() async {
    try {
      setState(() {
        _isLoading = true;
      });

      EasyLoading.show(
        status: '校验中...',
        maskType: EasyLoadingMaskType.black,
      );

      // 确保登录服务已初始化
      if (_loginService == null) {
        await _initializeLoginService();
      }

      // 准备登录参数
      final loginParams = [
        <String, dynamic>{
          'username': _usernameController.text,
          'password': _usePassword && _passwordController.text.isNotEmpty
              ? md5
                  .convert(utf8.encode(_passwordController.text + 'messi'))
                  .toString()
              : null,
          'face': _faceImageBase64,
          'handheldNo': _deviceInfo['deviceId'] ?? '',
          'isImport': true
        }
      ];

      final Map<String, dynamic> loginResult =
          await _loginService!.faceVerify(loginParams);

      if (loginResult['retCode'] == HTTPCode.success.code) {
        final List<dynamic>? userList =
            loginResult['retList'] as List<dynamic>?;
        _username = userList?[0]['userName'] as String?;

        EasyLoading.dismiss();
        // 下一步
        setState(() {
          _currentStep = AuthStep.vehicleVerify;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // 登录失败
        final String errorMessage =
            loginResult['message']?.toString() ?? '登录失败';
        _showError(errorMessage);
        EasyLoading.dismiss();
      }
    } catch (e) {
      AppLogger.error('登录过程中发生错误', e);
      _showError('登录失败: ${e.toString()}');
      EasyLoading.dismiss();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 返回上一步
  void _previousStep() {
    switch (_currentStep) {
      case AuthStep.login:
        // 已经是第一步，关闭弹框
        Navigator.of(context).pop();
        widget.onCancel?.call();
        break;
      case AuthStep.vehicleVerify:
        setState(() {
          _currentStep = AuthStep.login;
        });
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      case AuthStep.confirmVerify:
        setState(() {
          _currentStep = AuthStep.vehicleVerify;
        });
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
    }
  }

  /// 验证登录步骤
  bool _validateLoginStep() {
    // 验证人员
    if (_usernameController.text.isEmpty) {
      _showError('请输入用户名');
      return false;
    }

    // 根据登录方式验证
    if (_usePassword) {
      if (_passwordController.text.isEmpty) {
        _showError('请输入密码');
        return false;
      }
    } else {
      if (_faceImageBase64 == null || _faceImageBase64!.isEmpty) {
        _showError('请进行人脸拍照');
        return false;
      }
    }

    return true;
  }

  /// 验证车辆核验步骤
  bool _validateVehicleStep() {
    if (_scannedVehicleRfid == null || _scannedVehicleRfid!.isEmpty) {
      _showError('点击识别车辆');
      return false;
    }
    return true;
  }

  /// 判断当前步骤是否完成（不显示错误信息，仅用于按钮状态）
  bool _isStepValid() {
    switch (_currentStep) {
      case AuthStep.login:
        return _isLoginStepValid();
      case AuthStep.vehicleVerify:
        return _isVehicleStepValid();
      case AuthStep.confirmVerify:
        final bool allMatched = _isBothConsistent(context);
        if (allMatched) return true;
        return (_selectedMismatchReason != null &&
            _selectedMismatchReason!.trim().isNotEmpty);
    }
  }

  /// 判断车辆与人员是否都一致
  bool _isBothConsistent(BuildContext context) {
    // 人员一致性
    final lineInfoProvider =
        Provider.of<LineInfoProvider>(context, listen: false);
    final String expectedEscort = (lineInfoProvider.escortName ?? '').trim();
    final String actualEscort = _username?.trim() ?? '';
    final Color peopleColor =
        _comparisonColor(expectedEscort, actualEscort);

    // 车辆一致性
    final String expectedPlate =
        getPlateNumber(widget.vehicleRfidExpected ?? '').toString();
    final Color vehicleColor =
        _comparisonColor(expectedPlate, _vehiclePlateNumber);

    return peopleColor == Colors.green[700] &&
        vehicleColor == Colors.green[700];
  }

  /// 判断登录步骤是否完成
  bool _isLoginStepValid() {
    // 验证人员
    if (_usernameController.text.isEmpty) {
      return false;
    }

    // 根据登录方式验证
    if (_usePassword) {
      if (_passwordController.text.isEmpty) {
        return false;
      }
    } else {
      if (_faceImageBase64 == null || _faceImageBase64!.isEmpty) {
        return false;
      }
    }

    return true;
  }

  /// 判断车辆核验步骤是否完成
  bool _isVehicleStepValid() {
    return _scannedVehicleRfid != null && _scannedVehicleRfid!.isNotEmpty;
  }

  /// 完成认证
  void _completeAuth() {
    final result = AuthResult(
      success: true,
      errorMessage: _selectedMismatchReason,
    );
    Navigator.of(context).pop(result);
    widget.onComplete?.call(result);
  }

  /// 显示错误信息
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 拍照
  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 30,
        maxWidth: 640,
        maxHeight: 480,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (bytes.length > 500 * 1024) {
          _showError('图片太大，请重新拍照');
          return;
        }

        setState(() {
          _faceImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      _showError('拍照失败: ${e.toString()}');
    }
  }

  /// 处理车辆RFID扫描结果
  void _onVehicleRfidScanned(String rfid) async {
    setState(() {
      _scannedVehicleRfid = rfid;
      _isVehicleScanning = false;
      _vehiclePlateNumber = null; // 重置车牌号
    });

    // 调用接口查询车牌号
    bool hasPlateNumber = false;
    try {
      if (_loginService != null) {
        EasyLoading.show(
          status: '车牌查询中...',
          maskType: EasyLoadingMaskType.black,
        );
        final result = await _loginService!.getCarByLable(rfid);
        if (result['retCode'] == HTTPCode.success.code) {
          final List<dynamic>? carList = result['retList'] as List<dynamic>?;
          if (carList != null && carList.isNotEmpty) {
            final Map<String, dynamic> car =
                carList.first as Map<String, dynamic>;
            final String plate =
                (car['plate'] ?? car['carNo'] ?? '').toString();
            if (plate.isNotEmpty) {
              setState(() {
                _vehiclePlateNumber = plate;
              });
              hasPlateNumber = true;
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error('查询车牌号时发生错误', e);
    } finally {
      EasyLoading.dismiss();
      // 如果查询失败或没有结果，确保清除之前的车牌号
      if (!hasPlateNumber && mounted) {
        setState(() {
          _vehiclePlateNumber = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
        data: mq.copyWith(viewInsets: EdgeInsets.zero),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 标题栏
                _buildHeader(),
                const SizedBox(height: 16),

                // 内容区域
                Expanded(
                  child: MediaQuery(
                    data: mq,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildLoginStep(),
                        _buildVehicleVerifyStep(),
                        _buildConfirmVerifyStep(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 底部按钮
                _buildBottomButtons(),
              ],
            ),
          ),
        ));
  }

  /// 构建标题栏
  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: _previousStep,
          icon: const Icon(Icons.arrow_back),
        ),
        Expanded(
          child: Text(
            widget.title ?? '身份认证',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onCancel?.call();
          },
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  /// 构建登录步骤
  Widget _buildLoginStep() {
    return _buildPersonLogin();
  }

  /// 构建人员登录
  Widget _buildPersonLogin() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 80,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 用户名输入
                CustomTextField(
                  controller: _usernameController,
                  hintText: '请输入用户名',
                  prefixIcon: Icons.person,
                  obscureText: false,
                  fontSize: 12,
                ),
                const SizedBox(height: 8),

                const SizedBox(height: 12),
                // 人脸扫描区域或密码输入框
                if (_usePassword)
                  CustomTextField(
                    controller: _passwordController,
                    hintText: '请输入密码',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    fontSize: 12,
                  )
                else
                  Center(
                    child: FaceScanWidget(
                      onTap: () => _takePicture(),
                      width: 220,
                      height: 140,
                      frameColor: Colors.blue,
                      iconColor: Colors.blue,
                      iconSize: 60,
                      hintText: '点击进行人脸拍照',
                      imageBase64: _faceImageBase64,
                      onDelete: () {
                        setState(() {
                          _faceImageBase64 = null;
                        });
                      },
                    ),
                  ),

                const SizedBox(height: 12),
                // 切换登录方式按钮 - 底部右侧
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _usePassword = !_usePassword;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(80, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _usePassword ? '人脸登录' : '账号登录',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建车辆核验步骤
  Widget _buildVehicleVerifyStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // UHF扫描区域
        Expanded(
          child: UHFPluginWidget(
            builder: (context, controller) {
              // 保存 controller 的引用
              if (_vehicleScanController == null) {
                _vehicleScanController = controller;
              }

              // 保存 onScanStateChanged 回调的引用，用于手动触发状态更新
              late Function(bool) scanStateChangedCallback;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 扫描按钮（居中显示）
                  Container(
                    padding: const EdgeInsets.only(left: 20),
                    child: UHFScanButton(
                      startText: '点击识别车辆卡',
                      stopText: '点击识别车辆卡',
                      isAutoRefresh: true,
                      onTagScanned: (rfid) async {
                        // 允许重新扫描，覆盖已有结果
                        final last4 = rfid.length >= 4
                            ? rfid.substring(rfid.length - 4)
                            : rfid;
                        _onVehicleRfidScanned(last4);
                        // 扫描到即停止扫描，并确保状态同步
                        try {
                          await controller.stopScan();
                          // 手动触发状态变化回调，确保 UHFScanButton 状态同步，让按钮可以立即再次点击
                          scanStateChangedCallback(false);
                          // 重置防抖状态，确保可以立即重新扫描
                          await Future<void>.delayed(const Duration(milliseconds: 100));
                        } catch (e) {
                          // 忽略错误
                        }
                      },
                      onScanStateChanged: (isScanning) {
                        // 保存回调引用
                        scanStateChangedCallback = (bool state) {
                          if (!mounted) return;
                          setState(() {
                            _isVehicleScanning = state;
                            // 开始扫描时，清除之前的结果，允许重新扫描
                            if (state && _scannedVehicleRfid != null) {
                              _scannedVehicleRfid = null;
                              _vehiclePlateNumber = null;
                            }
                          });
                        };
                        scanStateChangedCallback(isScanning);
                      },
                      onError: _showError,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 扫描结果信息（标签ID、车牌号）
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '标签ID：',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Expanded(
                              child: Text(
                                _scannedVehicleRfid ?? '未扫描',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              '车牌号：',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Expanded(
                              child: Text(
                                _vehiclePlateNumber ?? '未查询到',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建确认核验步骤
  Widget _buildConfirmVerifyStep() {
    return Column(
      children: [
        const SizedBox(height: 16),

        // 显示核验信息
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            children: [
              // 车辆
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 32,
                    child: Text('车辆',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Text('原定',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black54)),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showFullText(
                                    '车辆原定',
                                    getPlateNumber(
                                        widget.vehicleRfidExpected ?? '')),
                                child: Text(
                                  _middleEllipsis(
                                              getPlateNumber(widget
                                                          .vehicleRfidExpected ??
                                                      '')
                                                  .toString(),
                                              head: 6,
                                              tail: 6)
                                          .isNotEmpty
                                      ? _middleEllipsis(
                                          getPlateNumber(
                                                  widget.vehicleRfidExpected ??
                                                      '')
                                              .toString(),
                                          head: 6,
                                          tail: 6)
                                      : 'null',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: const Text('实际',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.blue)),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    _showFullText('车辆实际', _vehiclePlateNumber),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: _badgeBackground(
                                      _comparisonColor(
                                          getPlateNumber(
                                                  widget.vehicleRfidExpected ??
                                                      '')
                                              .toString(),
                                          _vehiclePlateNumber),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _comparisonColor(
                                        getPlateNumber(
                                                widget.vehicleRfidExpected ?? '')
                                            .toString(),
                                        _vehiclePlateNumber,
                                      ).withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    _middleEllipsis(_vehiclePlateNumber,
                                                head: 6, tail: 6)
                                            .isNotEmpty
                                        ? _middleEllipsis(_vehiclePlateNumber,
                                            head: 6, tail: 6)
                                        : 'null',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _comparisonColor(
                                        getPlateNumber(
                                                widget.vehicleRfidExpected ?? '')
                                            .toString(),
                                        _vehiclePlateNumber,
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 人员
              Builder(builder: (context) {
                final lineInfoProvider =
                    Provider.of<LineInfoProvider>(context, listen: false);
                final escortName = (lineInfoProvider.escortName ?? '').trim();
                // 线路上的 escortName
                final expectedDisplay =
                    escortName.isNotEmpty ? escortName : '空';
                // 与实际押运员进行对比
                final expectedForCompare = escortName;

                final actualDisplay =
                    _username?.isNotEmpty ?? false ? _username! : '未输入';
                final actualForCompare = _username?.trim() ?? '';
                final color =
                    _comparisonColor(expectedForCompare, actualForCompare);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 32,
                      child: Text('人员',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: const Text('原定',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black54)),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      _showFullText('人员原定', expectedDisplay),
                                  child: Text(
                                    _middleEllipsis(expectedDisplay,
                                        head: 6, tail: 6),
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black87),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: const Text('实际',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.blue)),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      _showFullText('人员实际', actualDisplay),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: _badgeBackground(color),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: color.withOpacity(0.4)),
                                    ),
                                    child: Text(
                                      _middleEllipsis(actualDisplay,
                                          head: 6, tail: 6),
                                      style:
                                          TextStyle(fontSize: 14, color: color),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 不一致原因下拉框（仅在存在不一致时显示）
        if (!_isBothConsistent(context))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedMismatchReason,
                hint: const Text(
                  '请选择不一致原因',
                  style: TextStyle(fontSize: 12),
                ),
                items: _mismatchReasons
                    .map(
                      (reason) => DropdownMenuItem<String>(
                        value: reason,
                        child: Text(
                          reason,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMismatchReason = value;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  /// 构建底部按钮
  Widget _buildBottomButtons() {
    final bool isStepValid = _isStepValid();
    final bool isButtonEnabled = !_isLoading && isStepValid;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isButtonEnabled ? Colors.blue : Colors.grey,
              foregroundColor: Colors.white,
            ),
            onPressed: isButtonEnabled ? _nextStep : null,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _currentStep == AuthStep.confirmVerify ? '完成' : '下一步',
                    style: const TextStyle(fontSize: 12),
                  ),
          ),
        ),
      ],
    );
  }
}
