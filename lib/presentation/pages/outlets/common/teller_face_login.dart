import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/presentation/state/providers/teller_verify_provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/face_scan_widget.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/custom_text_field.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class TellerFaceLogin extends StatefulWidget {
  final int personIndex; // 添加索引

  const TellerFaceLogin({
    Key? key,
    required this.personIndex,
  }) : super(key: key);

  @override
  State<TellerFaceLogin> createState() => _TellerFaceLoginState();
}

class _TellerFaceLoginState extends State<TellerFaceLogin>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _picker = ImagePicker();
  final _scrollController = ScrollController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 初始化时从Provider获取已保存的数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<TellerVerifyProvider>(context, listen: false); // 获取Provider
      final savedUsername = provider.getUsername(widget.personIndex);
      final savedPassword = provider.getPassword(widget.personIndex);
      if (savedUsername != null) {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword ?? '';
      }
    });
    
    // 添加焦点监听器，当输入框获得焦点时自动滚动
    _usernameFocusNode.addListener(() {
      if (_usernameFocusNode.hasFocus) {
        _scrollToInput();
      }
    });
    
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        _scrollToInput();
      }
    });
  }
  
  // 滚动到输入框位置
  void _scrollToInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // 检查键盘是否弹起
  bool _isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  Future<void> _takePicture() async {
    try {

      // 显示拍照提示
      EasyLoading.show(
        status: '拍照中...',
        maskType: EasyLoadingMaskType.black,
      );
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 30, // 降低图片质量到30%
        maxWidth: 640,    // 限制最大宽度
        maxHeight: 480,   // 限制最大高度
      );

      if (photo != null) {
        EasyLoading.show(status: '处理中...');
        
        // 添加超时处理
        final bytes = await photo.readAsBytes().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('图片读取超时');
          },
        );
        
        // 检查图片大小
        if (bytes.length > 500 * 1024) { // 500KB限制
          throw Exception('图片太大，请重新拍照');
        }
        final base64String = base64Encode(bytes);

        // 在异步操作前获取Provider
        final provider = Provider.of<TellerVerifyProvider>(context, listen: false);
        provider.setFaceImage(widget.personIndex, base64String);
        EasyLoading.dismiss();
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (e is TimeoutException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('拍照超时，请重试')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: ${e.toString()}')),
        );
      }
      print('拍照失败: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TellerVerifyProvider>(
      builder: (context, provider, child) {
        final isFaceLogin = provider.isFaceLogin(widget.personIndex);
        final isKeyboardVisible = _isKeyboardVisible(context);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Container(
            // 键盘弹起时调整高度
            constraints: BoxConstraints(
              minHeight: isKeyboardVisible ? 300 : 220,
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    bottom: isKeyboardVisible ? 60 : 0, // 键盘弹起时增加底部间距
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 输入框
                      CustomTextField(
                        controller: _usernameController,
                        hintText: '请输入柜员号',
                        prefixIcon: Icons.person,
                        obscureText: false,
                        focusNode: _usernameFocusNode,
                        onChanged: (value) {
                          provider.setUsername(widget.personIndex, value);
                        },
                      ),
                      const SizedBox(height: 20),
                      // 人脸扫描区域或密码输入框
                      if (isFaceLogin)
                        Center(
                          child: FaceScanWidget(
                            onTap: _takePicture,
                            width: 200,
                            height: 120,
                            frameColor: Colors.blue,
                            iconColor: Colors.blue,
                            iconSize: 60,
                            hintText: '点击进行人脸拍照',
                            imageBase64:
                                provider.getFaceImage(widget.personIndex),
                            onDelete: () {
                              provider.setFaceImage(widget.personIndex, null);
                            },
                          ),
                        )
                      else
                        CustomTextField(
                          controller: _passwordController,
                          hintText: '请输入密码',
                          prefixIcon: Icons.lock,
                          obscureText: true,
                          focusNode: _passwordFocusNode,
                          onChanged: (value) {
                            provider.setPassword(widget.personIndex, value);
                          },
                        ),
                    ],
                  ),
                ),
                // 切换登录方式按钮 - 键盘弹起时隐藏
                if (!isKeyboardVisible)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            provider.toggleLoginMode(widget.personIndex);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(80, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            isFaceLogin ? '账号登录' : '人脸登录',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
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
  }
} 