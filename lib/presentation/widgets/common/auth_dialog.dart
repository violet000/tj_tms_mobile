import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/presentation/state/providers/face_login_provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/custom_text_field.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/face_scan_widget.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/uhf_plugin_widget.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/uhf_scan_button.dart';
import 'package:image_picker/image_picker.dart';
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
  final _picker = ImagePicker();
  String? _faceImageBase641;
  String? _faceImageBase642;

  // 登录方式状态 - 每个人员是否使用密码登录
  bool _usePassword1 = false;
  bool _usePassword2 = false;

  // 车辆核验相关
  String? _scannedVehicleRfid;
  bool _isVehicleScanning = false;

  // 人员核验相关
  String? _scannedPersonRfid;
  bool _isPersonScanning = false;

  // 状态管理
  bool _isLoading = false;
  String? _selectedMismatchReason;
  static const List<String> _mismatchReasons = <String>[
    '车辆标签损坏/无法读取',
    '车辆更换未同步',
    '人员录入信息错误',
    '设备读写异常',
    '其他'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();
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
      return Colors.grey[600]!;
    }
    if (expectedTrimmed.isEmpty) {
      return Colors.green[700]!;
    }
    return expectedTrimmed == actualTrimmed
        ? Colors.green[700]!
        : Colors.red[700]!;
  }

  bool _isEqual(String? expected, String? actual) {
    final String expectedTrimmed = (expected ?? '').trim();
    final String actualTrimmed = (actual ?? '').trim();
    if (expectedTrimmed.isEmpty || actualTrimmed.isEmpty) return false;
    return expectedTrimmed == actualTrimmed;
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
        content: SelectableText(text.isNotEmpty ? text : '无', style: const TextStyle(fontSize: 12)),
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
          setState(() {
            _currentStep = AuthStep.vehicleVerify;
          });
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
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
      _showError('请扫描车辆RFID');
      return false;
    }
    return true;
  }

  /// 完成认证
  void _completeAuth() {
    final result = AuthResult(
      success: true,
      username: '${_usernameController1.text},${_usernameController2.text}',
      password: _passwordController1.text.isNotEmpty ||
              _passwordController2.text.isNotEmpty
          ? '${_passwordController1.text},${_passwordController2.text}'
          : null,
      faceImage: _faceImageBase641 != null || _faceImageBase642 != null
          ? '${_faceImageBase641 ?? ''},${_faceImageBase642 ?? ''}'
          : null,
      vehicleRfid: _scannedVehicleRfid,
      personRfid: _scannedPersonRfid,
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
  void _onVehicleRfidScanned(String rfid) {
    setState(() {
      _scannedVehicleRfid = rfid;
      _isVehicleScanning = false;
    });
  }

  /// 处理人员RFID扫描结果
  void _onPersonRfidScanned(String rfid) {
    setState(() {
      _scannedPersonRfid = rfid;
      _isPersonScanning = false;
    });
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
                      startText: '车辆RFID扫描',
                      stopText: '车辆RFID停止',
                      onTagScanned: (rfid) {
                        _onVehicleRfidScanned(rfid);
                        // 扫描到即自动停止
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
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Expanded(
                              child: Text(
                                // 暂以RFID替代
                                _scannedVehicleRfid ?? '未扫描',
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
                    child: Text('车辆', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Text('原定', style: TextStyle(fontSize: 10, color: Colors.black54)),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _showFullText('车辆原定', widget.vehicleRfidExpected),
                              child: Text(
                                _middleEllipsis(widget.vehicleRfidExpected, head: 6, tail: 6).isNotEmpty
                                    ? _middleEllipsis(widget.vehicleRfidExpected, head: 6, tail: 6)
                                    : '无',
                                style: const TextStyle(fontSize: 11, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: const Text('实际', style: TextStyle(fontSize: 10, color: Colors.blue)),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _showFullText('车辆实际', _scannedVehicleRfid),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: _badgeBackground(
                                    _comparisonColor(widget.vehicleRfidExpected, _scannedVehicleRfid),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _comparisonColor(
                                      widget.vehicleRfidExpected,
                                      _scannedVehicleRfid,
                                    ).withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  _middleEllipsis(_scannedVehicleRfid, head: 6, tail: 6).isNotEmpty
                                      ? _middleEllipsis(_scannedVehicleRfid, head: 6, tail: 6)
                                      : '未扫描',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _comparisonColor(
                                      widget.vehicleRfidExpected,
                                      _scannedVehicleRfid,
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
                final faceLoginProvider =
                    Provider.of<FaceLoginProvider>(context, listen: false);
                final expected1 = (faceLoginProvider.getUsername(1) ?? '').trim();
                final expected2 = (faceLoginProvider.getUsername(2) ?? '').trim();
                // 文本显示为 两人占位
                final expectedDisplay =
                    '${expected1.isNotEmpty ? expected1 : '未设置'} / ${expected2.isNotEmpty ? expected2 : '未设置'}';
                // 比对仅在两人都存在时进行
                final expectedForCompare =
                    (expected1.isNotEmpty && expected2.isNotEmpty) ? '$expected1, $expected2' : '';

                final actual1 = _usernameController1.text.trim();
                final actual2 = _usernameController2.text.trim();
                final actualDisplay =
                    '${actual1.isNotEmpty ? actual1 : '未输入'} / ${actual2.isNotEmpty ? actual2 : '未输入'}';
                final actualForCompare =
                    (actual1.isNotEmpty && actual2.isNotEmpty) ? '$actual1, $actual2' : '';
                final color = _comparisonColor(expectedForCompare, actualForCompare);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 52,
                      child: Text('人员', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: const Text('原定', style: TextStyle(fontSize: 10, color: Colors.black54)),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _showFullText('人员原定', expectedDisplay),
                                child: Text(
                                  _middleEllipsis(expectedDisplay, head: 6, tail: 6),
                                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: const Text('实际', style: TextStyle(fontSize: 10, color: Colors.blue)),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _showFullText('人员实际', actualDisplay),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: _badgeBackground(color),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: color.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    _middleEllipsis(actualDisplay, head: 6, tail: 6),
                                    style: TextStyle(fontSize: 11, color: color),
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
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: _isLoading ? null : _nextStep,
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
