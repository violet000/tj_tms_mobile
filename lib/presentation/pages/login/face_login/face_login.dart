import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/presentation/state/providers/face_login_provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/face_scan_widget.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/custom_text_field.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:tj_tms_mobile/services/cloudwalk_face_plugin.dart';

class FaceLogin extends StatefulWidget {
  final int personIndex; // 添加索引

  const FaceLogin({
    Key? key,
    required this.personIndex,
  }) : super(key: key);

  @override
  State<FaceLogin> createState() => _FaceLoginState();
}

class _FaceLoginState extends State<FaceLogin>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 初始化时从Provider获取已保存的数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<FaceLoginProvider>(context, listen: false); // 获取Provider
      final savedUsername = provider.getUsername(widget.personIndex);
      final savedPassword = provider.getPassword(widget.personIndex);
      if (savedUsername != null) {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword ?? '';
      }
    });
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
          final provider = Provider.of<FaceLoginProvider>(context, listen: false);
          provider.setFaceImage(widget.personIndex, bestFace);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('活体检测成功'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('检测成功但未获取到人脸图片')),
          );
        }
      } else {
        // 检测失败或取消
        if (result.isCancelled) {
          // 用户取消了检测，不显示错误提示
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FaceLoginProvider>(
      builder: (context, provider, child) {
        final isFaceLogin = provider.isFaceLogin(widget.personIndex);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Container(
            height: 220,
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 输入框
                      CustomTextField(
                        controller: _usernameController,
                        hintText: '请输入押运员账号',
                        prefixIcon: Icons.person,
                        obscureText: false,
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
                          onChanged: (value) {
                            provider.setPassword(widget.personIndex, value);
                          },
                        ),
                    ],
                  ),
                ),
                // 切换登录方式按钮
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
