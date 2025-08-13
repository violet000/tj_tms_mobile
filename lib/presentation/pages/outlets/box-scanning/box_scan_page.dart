import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/presentation/state/providers/verify_token_provider.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/blue_polygon_background.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-scanning/box_scan_detail_page.dart';

class BoxScanPage extends StatefulWidget {
  const BoxScanPage({super.key});

  @override
  State<BoxScanPage> createState() => _BoxScanPageState();
}

class _BoxScanPageState extends State<BoxScanPage> {
  List<Map<String, dynamic>> lines = [];
  List<String> lineNoArray = [];
  Map<String, dynamic>? selectedRoute;
  Service18082? _service;
  late final VerifyTokenProvider _verifyTokenProvider;
  Future<List<Map<String, dynamic>>>? _linesFuture;
  int? _mode;
  // 自定义appBar
  PreferredSizeWidget appCustomBar(BuildContext context) {
    return AppBar(
      title: const Text(
        '网点交接',
        textAlign: TextAlign.left,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333)),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      leading: IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('mode')) {
        _mode = args['mode'] as int?;
      }
      _getEscortRouteToday();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _verifyTokenProvider = Provider.of<VerifyTokenProvider>(context, listen: false);
  }

  Future<void> _initializeService() async {
    _service = await Service18082.create();
  }

  Future<void> _getEscortRouteToday() async {
    try {
      if (_service == null) {
        await _initializeService();
      }
      final String? username =
          _verifyTokenProvider.getUserData()?['username'] as String?;
      if (username == null) {
        AppLogger.warning('用户名为空，无法获取线路数据');
        return;
      }
      final dynamic escortRouteToday =
          await _service!.getLineByEscortNo(username, mode: _mode);

      final List<dynamic>? rawList =
          escortRouteToday['retList'] as List<dynamic>?;
      if (rawList == null) {
        setState(() {
          lines = [];
          selectedRoute = null;
        });
        return;
      }
      for (final item in rawList) {
        if (item is Map<String, dynamic> && item.containsKey('lineNo')) {
          String lineNo = item['lineNo'].toString();
          if (!lineNoArray.contains(lineNo)) {
            lineNoArray.add(lineNo);
          }
        }
      }

      final List<Map<String, dynamic>> parsedLines =
          List<Map<String, dynamic>>.from(
              rawList.whereType<Map<String, dynamic>>() // 只保留列表中确定是Map的元素
              );
      setState(() {
        lines = parsedLines;
        if (lines.isNotEmpty) {
          selectedRoute = lines[0]; // 默认选中第一条
        } else {
          selectedRoute = null; // 如果没有数据则清空选中项
        }
      });
    } catch (e, s) {
      // 统一处理可能发生的任何错误
      AppLogger.error('获取或解析线路数据时发生错误', e, s);
      // 可以在这里弹出一个对话框告诉用户加载失败
      if (mounted) {
        setState(() {
          lines = [];
          selectedRoute = null;
        });
      }
    }
  }

  // 获取分组后的网点列表
  Map<String, List<Map<String, dynamic>>> _getGroupedPoints() {
    if (selectedRoute == null) return {};

    // 安全获取 planDTOS 列表
    final List<dynamic>? planDTOS =
        selectedRoute!['planDTOS'] as List<dynamic>?;
    if (planDTOS == null || planDTOS.isEmpty) {
      AppLogger.warning('selectedRoute 中的 planDTOS 为空');
      return {'出库网点': [], '入库网点': []};
    }

    // 用 Map 存储网点，key 为 orgNo（唯一标识），避免重复
    final Map<String, Map<String, dynamic>> deliverPointsMap = {};
    final Map<String, Map<String, dynamic>> receivePointsMap = {};

    for (var plan in planDTOS) {
      if (plan is! Map<String, dynamic>) continue;

      // 处理出库网点（deliverOrgNo）
      final List<dynamic>? deliverOrgNos =
          plan['deliverOrgNo'] as List<dynamic>?;
      if (deliverOrgNos != null) {
        for (var org in deliverOrgNos) {
          if (org is! Map<String, dynamic>) continue;
          // 获取唯一标识 orgNo，确保不为空
          final String? orgNo = org['orgNo']?.toString();
          if (orgNo == null || orgNo.isEmpty) continue;

          // 优先保留状态为 false 的数据（假设 false 是待处理的有效数据）
          // 如果已存在该 orgNo，仅在新数据状态为 false 时更新
          if (!deliverPointsMap.containsKey(orgNo) || org['status'] == false) {
            deliverPointsMap[orgNo] = <String, dynamic>{
              ...org,
              'operationType': 0, // 标记为出库
              // 补充网点显示所需的字段（如果原数据没有，避免UI报错）
              'pointName': org['orgName'] ?? '未知网点', // 适配UI中使用的pointName
              'address': org['address'] ?? '未知地址', // 适配UI中使用的address
              'implBoxDetail':
                  org['implBoxDetail'] ?? <Map<String, dynamic>>[], // 新增款箱数据
            };
          }
        }
      }

      // 处理入库网点（receiveOrgNo）
      final List<dynamic>? receiveOrgNos =
          plan['receiveOrgNo'] as List<dynamic>?;
      if (receiveOrgNos != null) {
        for (var org in receiveOrgNos) {
          if (org is! Map<String, dynamic>) continue;
          // 获取唯一标识 orgNo，确保不为空
          final String? orgNo = org['orgNo']?.toString();
          if (orgNo == null || orgNo.isEmpty) continue;

          // 同样按 orgNo 去重，优先保留有效状态
          if (!receivePointsMap.containsKey(orgNo) || org['status'] == false) {
            receivePointsMap[orgNo] = <String, dynamic>{
              ...org,
              'operationType': 1, // 标记为入库
              // 补充网点显示所需的字段
              'pointName': org['orgName'] ?? '未知网点',
              'address': org['address'] ?? '未知地址',
              'implBoxDetail':
                  org['implBoxDetail'] ?? <Map<String, dynamic>>[], // 新增款箱数据
            };
          }
        }
      }
    }

    // 将去重后的 Map 转为 List
    return {
      '出库网点': deliverPointsMap.values.toList(),
      '入库网点': receivePointsMap.values.toList(),
    };
  }

  // 构建网点项
  Widget _buildPointItem(Map<String, dynamic> point) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // 提取款箱数据
          List<Map<String, dynamic>> boxItems = [];
          final List<dynamic>? implBoxDetail =
              point['implBoxDetail'] as List<dynamic>?;
          if (implBoxDetail != null) {
            for (var impl in implBoxDetail) {
              if (impl is Map<String, dynamic>) {
                final List<dynamic>? boxDetail =
                    impl['boxDetail'] as List<dynamic>?;
                if (boxDetail != null) {
                  for (var box in boxDetail) {
                    if (box is Map<String, dynamic>) {
                      boxItems.add(<String, dynamic>{
                        'boxCode': box['boxNo'],
                        'scanStatus':
                            int.parse(box['boxHandStatus'].toString()),
                      });
                    }
                  }
                }
              }
            }
          }

          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (context) => BoxScanDetailPage(
                point: point,
                boxItems: boxItems,
                lines: lines, // 传递 lines 数据
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 12),
              Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: const Color(0xFF29A8FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(
                  'assets/icons/location_net_point.svg',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point['pointName'].toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 69, 68, 68),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      point['address'].toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 121, 120, 120),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: point['status'] == false
                        ? const Color.fromARGB(255, 244, 19, 19)
                        : const Color.fromARGB(255, 5, 231, 5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  point['status'] == false ? '未交接' : '已交接',
                  style: TextStyle(
                    fontSize: 12,
                    color: point['status'] == false
                        ? const Color.fromARGB(255, 244, 19, 19)
                        : const Color.fromARGB(255, 5, 231, 5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 自定义header
  Widget headerRouteLine(List<Map<String, dynamic>> lines) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.transparent,
      child: BluePolygonBackground(
        width: 900,
        height: 80,
        child: Center(
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(
                  'assets/icons/location_pointer.svg',
                  fit: BoxFit.contain,
                  width: 40,
                  height: 40,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    // borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<Map<String, dynamic>>(
                    value: selectedRoute,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    underline: const SizedBox(),
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                    items: lines.map((Map<String, dynamic> route) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: route,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  route['lineName'].toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 53, 52, 52),
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  route['carNo'].toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 53, 52, 52),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  route['escortName'].toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (Map<String, dynamic>? newValue) {
                      setState(() {
                        selectedRoute = newValue;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 客户列表
  Widget customerListWidget() {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        children: _getGroupedPoints().entries.map((entry) {
          if (entry.value.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroupHeader(entry.key, entry.value.length),
              ...entry.value.map<Widget>((point) => _buildPointItem(point)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // 构建标题(出入库网点)
  Widget _buildGroupHeader(String title, int count) {
    return Container(
      // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF5F5F5),
      child: Flex(
        direction: Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding:
                const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
            decoration: BoxDecoration(
                color: const Color(0xffB8C8E0),
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Text(
                  '$title:',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count个',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return Scaffold(
        appBar: appCustomBar(context),
        body: const Center(
          child: Text(
            '暂无数据',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: appCustomBar(context),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            headerRouteLine(lines),
            // 客户列表信息
            customerListWidget(),
          ],
        ),
      ),
    );
  }
}
