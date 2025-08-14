import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/blue_polygon_background.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-scanning/teller_face_login.dart';
import 'package:tj_tms_mobile/presentation/state/providers/teller_verify_provider.dart';
import 'package:tj_tms_mobile/presentation/state/providers/face_login_provider.dart';
import 'package:tj_tms_mobile/presentation/state/providers/line_info_provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class BoxScanVerifyPage extends StatefulWidget {
  const BoxScanVerifyPage({super.key});

  @override
  State<BoxScanVerifyPage> createState() => _BoxScanVerifyPageState();
}

class _BoxScanVerifyPageState extends State<BoxScanVerifyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _lineName = args['lineName']?.toString() ?? '';
      _items = (args['items'] as List?)?.length.toString() ?? '0';
      _escortName = args['escortName']?.toString() ?? '';

      // 设置 LineInfoProvider 的数据
      final lineInfoProvider =
          Provider.of<LineInfoProvider>(context, listen: false);
      lineInfoProvider.setLineInfo(<String, dynamic>{
        'lineName': _lineName,
        'escortName': _escortName,
        'items': args['items'] as List?,
        'orgName': args['orgName']?.toString() ?? '',
      });
    }
  }

  Future<void> _initializeService() async {
    _service = await Service18082.create();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 自定义内容体的头部 - 添加线路、车、押运员信息
  Widget customBodyHeader() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: Colors.transparent,
        child: BluePolygonBackground(
            width: double.infinity, // 使用响应式宽度
            height: 120,
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
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 64,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4), // 减少边距
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8), // 减少内边距
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/personal.svg',
                                    width: 20, // 稍微减小图标
                                    height: 20,
                                  ),
                                  const SizedBox(width: 6), // 减少间距
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '押运员',
                                          style: TextStyle(
                                            fontSize: 11, // 稍微减小字体
                                            color: Color(0xFF888888),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Flexible(
                                          child: Text(
                                            _escortName.isEmpty
                                                ? '-'
                                                : _escortName,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1, // 限制最大行数
                                            style: const TextStyle(
                                              fontSize: 13, // 稍微减小字体
                                              color: Color(0xFF333333),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 64,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4), // 减少边距
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8), // 减少内边距
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/matbox.svg',
                                    width: 20, // 稍微减小图标
                                    height: 20,
                                  ),
                                  const SizedBox(width: 6), // 减少间距
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '款箱数量',
                                          style: TextStyle(
                                            fontSize: 11, // 稍微减小字体
                                            color: Color(0xFF888888),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Flexible(
                                          child: Text(
                                            '${_items.isEmpty ? '-' : _items} 个',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1, // 限制最大行数
                                            style: const TextStyle(
                                              fontSize: 13, // 稍微减小字体
                                              color: Color(0xFF333333),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            )));
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
          customBodyHeader(),
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Tab切换栏
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF29A8FF),
                    unselectedLabelColor: const Color(0xFF666666),
                    indicatorColor: const Color(0xFF29A8FF),
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: '柜员1'),
                      Tab(text: '柜员2'),
                    ],
                  ),
                ),
                // Tab内容区域
                SizedBox(
                  height: 300, // 减少高度，为底部按钮留出空间
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTellerContent(0), // 使用0和1作为personIndex
                      _buildTellerContent(1),
                    ],
                  ),
                ),
              ],
            ),
          ),
          footerButton(), // 底部按钮
        ],
      ),
    );
  }

  // 构建柜员内容区域，使用TellerFaceLogin组件
  Widget _buildTellerContent(int personIndex) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // 使用TellerFaceLogin组件
          Expanded(
            child: TellerFaceLogin(personIndex: personIndex),
          ),
        ],
      ),
    );
  }

  // 底部按钮控件
  Widget footerButton() {
    return Container(
      padding: const EdgeInsets.only(left: 6, right: 6, bottom: 6, top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                await _verifyAllTellers();
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('确认复核'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 2, 112, 215),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 验证所有柜员
  Future<void> _verifyAllTellers() async {
    final TellerVerifyProvider tellerProvider = Provider.of<TellerVerifyProvider>(context, listen: false);
    final FaceLoginProvider faceLoginProvider = Provider.of<FaceLoginProvider>(context, listen: false);
    
    // 验证两个柜员
    for (int i = 1; i <= 2; i++) {
      final int personIndex = i - 1;
      final String? username = tellerProvider.getUsername(personIndex);
      final String? password = tellerProvider.getPassword(personIndex);
      final String? faceImage = tellerProvider.getFaceImage(personIndex);

      // 验证规则：username必须存在，password或者faceImage其中满足一项就校验通过
      if (username == null || username.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请输入柜员${i}的柜员号')),
        );
        return;
      }

      // 检查是否有密码或人脸图片
      final bool hasPassword = password != null && password.isNotEmpty;
      final bool hasFaceImage = faceImage != null && faceImage.isNotEmpty;

      if (!hasPassword && !hasFaceImage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请输入柜员${i}的密码或进行人脸拍照')),
        );
        return;
      }
    }

    // 检查登录人员的押运员信息
    final String? escort1 = faceLoginProvider.getUsername(0);
    final String? escort2 = faceLoginProvider.getUsername(1);
    
    if (escort1 == null || escort1.isEmpty || escort2 == null || escort2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录人员信息不完整，请重新登录')),
      );
      return;
    }

    // 所有验证通过，先进行人脸登录核验
    try {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      if (args == null) {
        throw Exception('页面参数为空');
      }

      final dynamic implBoxDetail = args['implBoxDetail'];
      final String? outTre = args['operationType']?.toString();
      final String? isConsistent = args['isConsistent']?.toString();
      
      if (implBoxDetail == null || outTre == null) {
        throw Exception('缺少参数');
      }

      final String hander = tellerProvider.getUsername(1) ?? '';
      final String deliver = tellerProvider.getUsername(0) ?? '';
      final String escortNo = '$escort1/$escort2';

      // 获取柜员的密码和人脸图片
      final String? handerPassword = tellerProvider.getPassword(1);
      final String? handerFaceImage = tellerProvider.getFaceImage(1);
      final String? deliverPassword = tellerProvider.getPassword(0);
      final String? deliverFaceImage = tellerProvider.getFaceImage(0);

      // 构建人脸登录参数
      final List<Map<String, dynamic>> faceLoginParams = [];
      
      // 添加 hander 的登录参数
      if (hander.isNotEmpty) {
        faceLoginParams.add(<String, dynamic>{
          'username': hander,
          'password': (handerPassword == null || handerPassword.isEmpty) 
              ? null 
              : md5.convert(utf8.encode(handerPassword + 'messi')).toString(),
          'face': handerFaceImage,
          'isImport': true
        });
      }

      // 添加 deliver 的登录参数
      if (deliver.isNotEmpty) {
        faceLoginParams.add(<String, dynamic>{
          'username': deliver,
          'password': (deliverPassword == null || deliverPassword.isEmpty) 
              ? null 
              : md5.convert(utf8.encode(deliverPassword + 'messi')).toString(),
          'face': deliverFaceImage,
          'isImport': false
        });
      }

      // 调用人脸登录接口进行核验
      bool faceLoginSuccess = false;
      bool handoverSuccess = false;
      
      if (faceLoginParams.isNotEmpty) {
        EasyLoading.show(status: '核验柜员身份中...');
        try {
          await _service?.accountLogin(faceLoginParams);
          faceLoginSuccess = true;
        } catch (e) {
          faceLoginSuccess = false;
          throw Exception('柜员身份核验失败: ${e.toString()}');
        }
      } else {
        faceLoginSuccess = false;
      }
      EasyLoading.dismiss();

      // 只有人脸登录核验成功后才调用交接接口
      if (faceLoginSuccess) {
        EasyLoading.show(status: '提交复核...');
        try {
          await _service?.outletHandover(<String, dynamic>{
            'implNo': implBoxDetail.map((dynamic e) => int.parse(e['implNo'] as String)).toList(),
            'outTre': outTre,
            'hander': hander,
            'escortNo': escortNo,
            'deliver': deliver,
            'inconsistent': isConsistent,
          });
          handoverSuccess = true;
        } catch (e) {
          handoverSuccess = false;
          throw Exception('交接接口调用失败: ${e.toString()}');
        }
      }
      
      if (faceLoginSuccess && handoverSuccess && mounted) {
        Navigator.pushNamed(context, '/outlets/box-scan-verify-success');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('验证失败: ${e.toString()}')),
      );
    } finally {
      EasyLoading.dismiss();
    }
  }


}
