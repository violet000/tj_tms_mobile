import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/blue_polygon_background.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BoxScanVerifyPage extends StatefulWidget {
  const BoxScanVerifyPage({super.key});

  @override
  State<BoxScanVerifyPage> createState() => _BoxScanVerifyPageState();
}

class _BoxScanVerifyPageState extends State<BoxScanVerifyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  Uint8List? _faceImage;
  bool _isLoading = false;
  Service18082? _service;
  String _lineName = '';
  String _items = '';
  String _escortName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _lineName = args['lineName']?.toString() ?? '';
      _items = (args['items'] as List?)?.length.toString() ?? '0';
      _escortName = args['escortName']?.toString() ?? '';
    }
  }

  Future<void> _initializeService() async {
    _service = await Service18082.create();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _faceImage = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: $e')),
        );
      }
    }
  }

  // 自定义内容体的头部 - 添加线路、车、押运员信息
  Widget customBodyHeader(List<Map<String, dynamic>> items) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: Colors.transparent,
        child: BluePolygonBackground(
            width: 900,
            height: 100,
            child: Column(
              children: [
                // 顶部信息区和下方内容区完整布局
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部信息行
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // 信息项容器
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "线路信息",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${_lineName.isEmpty ? '-' : _lineName}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    // 下方白色内容区
                    Container(
                      margin: const EdgeInsets.only(left: 16, right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/personal.svg',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '押运员',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF888888),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _escortName.isEmpty ? '-' : _escortName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 160,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/matbox.svg',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '款箱数量',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF888888),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_items.isEmpty ? '-' : _items} 个',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF333333),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ))
        );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '款箱复核',
      showBackButton: true,
      onBackPressed: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      },
      child: Column(
        children: [
          customBodyHeader([]),
        ],
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('款箱复核'),
  //       backgroundColor: const Color(0xFF29A8FF),
  //       foregroundColor: Colors.white,
  //     ),
  //     body: Column(
  //       children: [
  //         // 押运线路信息
  //         Container(
  //           padding: const EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.05),
  //                 blurRadius: 10,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               const Text(
  //                 '押运线路信息',
  //                 style: TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                   color: Color(0xFF333333),
  //                 ),
  //               ),
  //               const SizedBox(height: 16),
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: const[
  //                         Text(
  //                           '线路编号',
  //                           style: TextStyle(
  //                             fontSize: 14,
  //                             color: Color(0xFF666666),
  //                           ),
  //                         ),
  //                         SizedBox(height: 4),
  //                         Text(
  //                           '111',
  //                           style: TextStyle(
  //                             fontSize: 16,
  //                             color: Color(0xFF333333),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         const Text(
  //                           '交接箱子数量',
  //                           style: TextStyle(
  //                             fontSize: 14,
  //                             color: Color(0xFF666666),
  //                           ),
  //                         ),
  //                         const SizedBox(height: 4),
  //                         Text(
  //                           '1个',
  //                           style: const TextStyle(
  //                             fontSize: 16,
  //                             color: Color(0xFF333333),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //         // Tab切换栏
  //         Container(
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.05),
  //                 blurRadius: 10,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           child: TabBar(
  //             controller: _tabController,
  //             labelColor: const Color(0xFF29A8FF),
  //             unselectedLabelColor: const Color(0xFF666666),
  //             indicatorColor: const Color(0xFF29A8FF),
  //             tabs: const [
  //               Tab(text: '账号密码验证'),
  //               Tab(text: '人脸验证'),
  //             ],
  //           ),
  //         ),
  //         // Tab内容
  //         Expanded(
  //           child: TabBarView(
  //             controller: _tabController,
  //             children: [
  //               // 账号密码验证
  //               Padding(
  //                 padding: const EdgeInsets.all(16),
  //                 child: Column(
  //                   children: [
  //                     TextField(
  //                       controller: _usernameController,
  //                       decoration: const InputDecoration(
  //                         labelText: '账号',
  //                         border: OutlineInputBorder(),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 16),
  //                     TextField(
  //                       controller: _passwordController,
  //                       decoration: const InputDecoration(
  //                         labelText: '密码',
  //                         border: OutlineInputBorder(),
  //                       ),
  //                       obscureText: true,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               // 人脸验证
  //               Center(
  //                 child: Column(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     if (_faceImage != null)
  //                       Container(
  //                         width: 200,
  //                         height: 200,
  //                         decoration: BoxDecoration(
  //                           border: Border.all(color: const Color(0xFF29A8FF)),
  //                           borderRadius: BorderRadius.circular(8),
  //                         ),
  //                         child: ClipRRect(
  //                           borderRadius: BorderRadius.circular(8),
  //                           child: Image.memory(
  //                             _faceImage as Uint8List,
  //                             fit: BoxFit.cover,
  //                           ),
  //                         ),
  //                       )
  //                     else
  //                       Container(
  //                         width: 200,
  //                         height: 200,
  //                         decoration: BoxDecoration(
  //                           border: Border.all(color: const Color(0xFF29A8FF)),
  //                           borderRadius: BorderRadius.circular(8),
  //                         ),
  //                         child: const Icon(
  //                           Icons.camera_alt,
  //                           size: 48,
  //                           color: Color(0xFF29A8FF),
  //                         ),
  //                       ),
  //                     const SizedBox(height: 16),
  //                     ElevatedButton.icon(
  //                       onPressed: _takePicture,
  //                       icon: const Icon(Icons.camera_alt),
  //                       label: const Text('拍摄人脸照片'),
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: const Color(0xFF29A8FF),
  //                         foregroundColor: Colors.white,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //     bottomNavigationBar: Container(
  //       padding: const EdgeInsets.all(16),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.05),
  //             blurRadius: 10,
  //             offset: const Offset(0, -2),
  //           ),
  //         ],
  //       ),
  //       child: ElevatedButton(
  //         onPressed: _isLoading ? null : _handleSubmit,
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: const Color(0xFF29A8FF),
  //           foregroundColor: Colors.white,
  //           padding: const EdgeInsets.symmetric(vertical: 16),
  //         ),
  //         child: _isLoading
  //             ? const SizedBox(
  //                 width: 24,
  //                 height: 24,
  //                 child: CircularProgressIndicator(
  //                   strokeWidth: 2,
  //                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
  //                 ),
  //               )
  //             : const Text('提交复核'),
  //       ),
  //     ),
  //   );
  // }
}
