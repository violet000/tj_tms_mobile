import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/presentation/state/providers/teller_verify_provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/face_scan_widget.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/custom_text_field.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:tj_tms_mobile/services/cloudwalk_face_plugin.dart';

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
      EasyLoading.show(
        status: '启动活体检测...',
        maskType: EasyLoadingMaskType.black,
      );

      // 直接启动活体检测，SDK会自动获取所需的参数
      final result = await CloudwalkFacePlugin.startLiveDetection();

      EasyLoading.dismiss();

      // 处理检测结果
      if (result.success) {
        // 检测成功，获取最佳人脸图片
        final bestFace = result.bestFace;
        if (bestFace != null && bestFace.isNotEmpty) {
          // 保存人脸图片到 Provider
          final provider = Provider.of<TellerVerifyProvider>(context, listen: false);
          provider.setFaceImage(widget.personIndex, bestFace);
        }
      } else {
        // 检测失败或取消
        if (result.isCancelled) {
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('活体检测失败: ${result.errorMsg ?? result.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('活体检测异常: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      print('活体检测失败: $e');
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
                            hintText: '点击进行活体检测',
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