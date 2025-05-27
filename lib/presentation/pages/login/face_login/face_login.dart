import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/presentation/state/providers/face_login_provider.dart';
import 'package:tj_tms_mobile/presentation/pages/login/face_login/face_input_widget.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/face_scan_widget.dart';

class FaceLogin extends StatefulWidget {
  final int personIndex; // 添加索引

  const FaceLogin({
    Key? key,
    required this.personIndex,
  }) : super(key: key);

  @override
  State<FaceLogin> createState() => _FaceLoginState();
}

class _FaceLoginState extends State<FaceLogin> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 初始化时从Provider获取已保存的数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<FaceLoginProvider>(context, listen: false); // 获取Provider
      final savedUsername = provider.getUsername(widget.personIndex);
      if (savedUsername != null) {
        _usernameController.text = savedUsername;
      }
    });
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );
      
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final base64String = base64Encode(bytes);
        
        // 在异步操作前获取Provider
        final provider = Provider.of<FaceLoginProvider>(context, listen: false);
        provider.setFaceImage(widget.personIndex, base64String);
      }
    } catch (e) {
      print('拍照失败: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FaceLoginProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Container(
            height: 220,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 输入框
                  FaceInputWidget(
                    controller: _usernameController,
                    onChanged: (value) {
                      provider.setUsername(widget.personIndex, value);
                    },
                  ),
                  const SizedBox(height: 20),
                  // 人脸扫描区域
                  Center(
                    child: FaceScanWidget(
                      onTap: _takePicture,
                      width: 200,
                      height: 120,
                      frameColor: Colors.blue,
                      iconColor: Colors.blue,
                      iconSize: 60,
                      hintText: '点击进行人脸拍照',
                      imageBase64: provider.getFaceImage(widget.personIndex),
                      onDelete: () {
                        provider.setFaceImage(widget.personIndex, null);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 账号登录按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          print("处理账号登录跳转");
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(80, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '账号登录',
                          style: TextStyle(
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
          ),
        );
      },
    );
  }
}