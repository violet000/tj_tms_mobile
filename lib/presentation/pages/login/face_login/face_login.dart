import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:tj_tms_mobile/presentation/widgets/common/custom_text_field.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/face_scan_widget.dart';

class FaceLogin extends StatefulWidget {
  const FaceLogin({Key? key}) : super(key: key);

  @override
  State<FaceLogin> createState() => _FaceLoginState();
}

class _FaceLoginState extends State<FaceLogin> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _isScanning = false;
  String? _imageBase64; // 存储base64图片数据
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initScanAnimation();
  }

  void _initScanAnimation() {
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_scanController);
  }

  // 拍照
  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        // preferredCameraDevice: CameraDevice.front, // 使用前置摄像头
        imageQuality: 50, // 压缩图片质量
      );
      
      if (photo != null) {
        // 将图片转换为base64
        final bytes = await photo.readAsBytes();
        final base64String = base64Encode(bytes);
        
        setState(() {
          _imageBase64 = base64String;
        });
        print('_imageBase64: $_imageBase64');
        // TODO: 处理拍摄的照片，可以发送到服务器进行人脸识别
        print('照片已保存: ${photo.path}');
      }
    } catch (e) {
      print('拍照失败: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 输入框
          CustomTextField(
            controller: _usernameController,
            hintText: '请输入柜员号',
            prefixIcon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入柜员号';
              }
              return null;
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
              imageBase64: _imageBase64, // 传入base64图片数据
            ),
          ),
          const Spacer(),
          // 账号登录按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.end, // 右对齐
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
    );
  }
}