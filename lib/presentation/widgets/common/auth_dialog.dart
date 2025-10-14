import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/core/constants/constant.dart';
import 'package:tj_tms_mobile/presentation/state/providers/face_login_provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/custom_text_field.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/face_scan_widget.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/uhf_plugin_widget.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/uhf_scan_button.dart';
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

class _AuthDialogState extends State<AuthDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  AuthStep _currentStep = AuthStep.login;

  // 登录相关 - 两个人员
  final _usernameController1 = TextEditingController();
  final _passwordController1 = TextEditingController();
  final _usernameController2 = TextEditingController();
  final _passwordController2 = TextEditingController();
  String? _username1 = null;
  String? _username2 = null;
  final _picker = ImagePicker();
  String? _faceImageBase641;
  String? _faceImageBase642;

  // 登录方式状态 - 每个人员是否使用密码登录
  bool _usePassword1 = false;
  bool _usePassword2 = false;

  // 车辆核验相关
  String? _scannedVehicleRfid;
  String? _vehiclePlateNumber; // 车牌号
  bool _isVehicleScanning = false;

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
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();
    _initializeLoginService();
    _loadDeviceInfo();

    // 为输入框添加监听器，实时更新按钮状态
    _usernameController1.addListener(_onInputChanged);
    _passwordController1.addListener(_onInputChanged);
    _usernameController2.addListener(_onInputChanged);
    _passwordController2.addListener(_onInputChanged);
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
    AppLogger.info('expectedTrimmed: $expectedTrimmed');
    AppLogger.info('actualTrimmed: $actualTrimmed');
    if (actualTrimmed.isEmpty) {
      return Colors.red[700]!;
    }
    if (expectedTrimmed.isEmpty) {
      return Colors.red[700]!;
    }
    return expectedTrimmed == actualTrimmed
        ? Colors.green[700]!
        : Colors.red[700]!;
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
    _tabController.dispose();
    _pageController.dispose();
    _usernameController1.dispose();
    _passwordController1.dispose();
    _usernameController2.dispose();
    _passwordController2.dispose();
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
          'username': _usernameController1.text,
          'password': _usePassword1 && _passwordController1.text.isNotEmpty
              ? md5
                  .convert(utf8.encode(_passwordController1.text + 'messi'))
                  .toString()
              : null,
          'face': _faceImageBase641,
          'handheldNo': _deviceInfo['deviceId'] ?? '',
          'isImport': true
        },
        <String, dynamic>{
          'username': _usernameController2.text,
          'password': _usePassword2 && _passwordController2.text.isNotEmpty
              ? md5
                  .convert(utf8.encode(_passwordController2.text + 'messi'))
                  .toString()
              : null,
          'face': _faceImageBase642,
          'handheldNo': _deviceInfo['deviceId'] ?? '',
          'isImport': false
        }
      ];

      final Map<String, dynamic> loginResult =
          await _loginService!.faceVerify(loginParams);

      if (loginResult['retCode'] == HTTPCode.success.code) {
        final List<dynamic>? userList =
            loginResult['retList'] as List<dynamic>?;
        _username1 = userList?[0]['userName'] as String?;
        _username2 = userList?[1]['userName'] as String?;

        AppLogger.info('登录成功 - 用户1: $_username1, 用户2: $_username2');

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
    // 验证第一个人员
    if (_usernameController1.text.isEmpty) {
      _showError('请输入第一个人员的用户名');
      return false;
    }

    // 验证第二个人员
    if (_usernameController2.text.isEmpty) {
      _showError('请输入第二个人员的用户名');
      return false;
    }

    // 根据登录方式验证
    if (_usePassword1) {
      if (_passwordController1.text.isEmpty) {
        _showError('第一个人员请输入密码');
        return false;
      }
    } else {
      if (_faceImageBase641 == null || _faceImageBase641!.isEmpty) {
        _showError('第一个人员请进行人脸拍照');
        return false;
      }
    }

    if (_usePassword2) {
      if (_passwordController2.text.isEmpty) {
        _showError('第二个人员请输入密码');
        return false;
      }
    } else {
      if (_faceImageBase642 == null || _faceImageBase642!.isEmpty) {
        _showError('第二个人员请进行人脸拍照');
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
        return true; // 确认步骤总是可以完成
    }
  }

  /// 判断登录步骤是否完成
  bool _isLoginStepValid() {
    // 验证第一个人员
    if (_usernameController1.text.isEmpty) {
      return false;
    }

    // 验证第二个人员
    if (_usernameController2.text.isEmpty) {
      return false;
    }

    // 根据登录方式验证
    if (_usePassword1) {
      if (_passwordController1.text.isEmpty) {
        return false;
      }
    } else {
      if (_faceImageBase641 == null || _faceImageBase641!.isEmpty) {
        return false;
      }
    }

    if (_usePassword2) {
      if (_passwordController2.text.isEmpty) {
        return false;
      }
    } else {
      if (_faceImageBase642 == null || _faceImageBase642!.isEmpty) {
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
  Future<void> _takePicture(int personIndex) async {
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
          if (personIndex == 1) {
            _faceImageBase641 = base64Encode(bytes);
          } else {
            _faceImageBase642 = base64Encode(bytes);
          }
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
            }
          } else {
            AppLogger.warning('查询车牌号失败: 未返回车辆列表');
          }
        } else {
          AppLogger.warning('查询车牌号失败: ${result['message']}');
        }
      }
    } catch (e) {
      AppLogger.error('查询车牌号时发生错误', e);
    } finally {
      EasyLoading.dismiss();
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
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: Colors.blue, width: 1),
              insets: EdgeInsets.symmetric(horizontal: 8),
            ),
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey[600],
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: const [
              Tab(height: 32, text: '押运员1'),
              Tab(height: 32, text: '押运员2'),
            ],
            labelStyle: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(height: 8),
        // Tab内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPersonLogin(1),
              _buildPersonLogin(2),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建人员登录
  Widget _buildPersonLogin(int personIndex) {
    final usernameController =
        personIndex == 1 ? _usernameController1 : _usernameController2;
    final passwordController =
        personIndex == 1 ? _passwordController1 : _passwordController2;
    final faceImage = personIndex == 1 ? _faceImageBase641 : _faceImageBase642;
    final usePassword = personIndex == 1 ? _usePassword1 : _usePassword2;

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
                  controller: usernameController,
                  hintText: '请输入用户名',
                  prefixIcon: Icons.person,
                  obscureText: false,
                  fontSize: 12,
                ),
                const SizedBox(height: 8),

                const SizedBox(height: 12),
                // 人脸扫描区域或密码输入框
                if (usePassword)
                  CustomTextField(
                    controller: passwordController,
                    hintText: '请输入密码',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    fontSize: 12,
                  )
                else
                  Center(
                    child: FaceScanWidget(
                      onTap: () => _takePicture(personIndex),
                      width: 220,
                      height: 140,
                      frameColor: Colors.blue,
                      iconColor: Colors.blue,
                      iconSize: 60,
                      hintText: '点击进行人脸拍照',
                      imageBase64: faceImage,
                      onDelete: () {
                        setState(() {
                          if (personIndex == 1) {
                            _faceImageBase641 = null;
                          } else {
                            _faceImageBase642 = null;
                          }
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
                          if (personIndex == 1) {
                            _usePassword1 = !_usePassword1;
                          } else {
                            _usePassword2 = !_usePassword2;
                          }
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(80, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        usePassword ? '人脸登录' : '账号登录',
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 扫描按钮（居中显示）
                  Container(
                    padding: const EdgeInsets.only(left: 20),
                    child: UHFScanButton(
                      startText: '点击识别车辆卡',
                      onTagScanned: (rfid) {
                        final last4 = rfid.length >= 4 ? rfid.substring(rfid.length - 4) : rfid;
                        _onVehicleRfidScanned(last4);
                        // 扫描到即停止扫描
                        controller.stopScan();
                      },
                      onScanStateChanged: (isScanning) {
                        setState(() {
                          _isVehicleScanning = isScanning;
                        });
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
                    width: 52,
                    child: Text('车辆',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                            GestureDetector(
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
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                            GestureDetector(
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
                // 与实际两人合并后的字符串进行对比（用逗号间隔）
                final expectedForCompare = escortName;

                final actualDisplay =
                    '${_username1?.isNotEmpty ?? false ? _username1 : '未输入'} / ${_username2?.isNotEmpty ?? false ? _username2 : '未输入'}';
                final actualForCompare = ((_username1?.isNotEmpty ?? false) &&
                        (_username2?.isNotEmpty ?? false))
                    ? '$_username1/$_username2'
                    : (_username1?.trim() ?? '') +
                        (_username2?.trim() ?? '').trim();
                final color =
                    _comparisonColor(expectedForCompare, actualForCompare);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 52,
                      child: Text('人员',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                              GestureDetector(
                                onTap: () =>
                                    _showFullText('人员原定', expectedDisplay),
                                child: Text(
                                  _middleEllipsis(expectedDisplay,
                                      head: 6, tail: 6),
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                                        fontSize: 10, color: Colors.blue)),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
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
                                        TextStyle(fontSize: 11, color: color),
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
        // 不一致原因下拉框
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
