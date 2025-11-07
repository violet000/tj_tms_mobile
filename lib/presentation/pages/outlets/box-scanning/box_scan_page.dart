import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:tj_tms_mobile/presentation/state/providers/verify_token_provider.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/blue_polygon_background.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-scanning/box_scan_detail_page.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:tj_tms_mobile/core/constants/constant.dart';
import 'package:tj_tms_mobile/core/utils/util.dart';

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
    _verifyTokenProvider =
        Provider.of<VerifyTokenProvider>(context, listen: false);
  }

  Future<void> _initializeService() async {
    _service = await Service18082.create();
  }

  // 获取线路数据
  Future<void> _getEscortRouteToday() async {
    try {
      if (_service == null) {
        await _initializeService();
      }
      final allNames = _verifyTokenProvider.getAllUsersData();
      final userName = allNames.map<String>((e) => e['username'].toString()).toList();
      EasyLoading.show(
        status: '加载中...',
        maskType: EasyLoadingMaskType.black,
      );
      final dynamic escortRouteToday =
          await _service!.getLineByEscortNo(userName, mode: _mode);

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
      AppLogger.error('获取或解析线路数据时发生错误', e, s);
      if (mounted) {
        setState(() {
          lines = [];
          selectedRoute = null;
        });
      }
    } finally {
      EasyLoading.dismiss();
    }
  }

  // 获取分组后的网点列表
  Map<PointType, List<Map<String, dynamic>>> _getGroupedPoints() {
    if (selectedRoute == null) return {};

    // 安全获取 planDTOS 列表
    final List<dynamic>? planDTOS =
        selectedRoute!['planDTOS'] as List<dynamic>?;
    if (planDTOS == null || planDTOS.isEmpty) {
      return {
        PointType.deliverPoint: [],
        PointType.receivePoint: [],
      };
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
              'operationType': InOutStatus.outlet.code, // 标记为出库
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
              'operationType': InOutStatus.inlet.code, // 标记为入库
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
      PointType.deliverPoint: deliverPointsMap.values.toList(),
      PointType.receivePoint: receivePointsMap.values.toList(),
    };
  }

  // 构建网点项
  Widget _buildPointItem(Map<String, dynamic> point) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (point['status'] == true) {
            return;
          }
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
                operationType: point['operationType'],
                implBoxDetail: point['implBoxDetail'],
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
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4), // 左右间距4
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    // borderRadius: BorderRadius.circular(8),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 800),
                    child: DropdownButton<Map<String, dynamic>>(
                    value: selectedRoute,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    underline: const SizedBox(),
                    menuMaxHeight: 400,
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                    selectedItemBuilder: (BuildContext context) {
                      return lines.map<Widget>((Map<String, dynamic> route) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  route['lineName'].toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  getPlateNumber(route['carNo'].toString()),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  route['escortName'].toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    items: lines.map((Map<String, dynamic> route) {
                      // 计算每个文本的长度，用于动态分配空间
                      final lineNameLength = route['lineName'].toString().length;
                      final carNoLength = getPlateNumber(route['carNo'].toString()).length;
                      final escortNameLength = route['escortName'].toString().length;
                      
                      // 计算总长度
                      final totalLength = lineNameLength + carNoLength + escortNameLength;
                      
                      // 根据文本长度按比例分配 flex 值，最小值为 1，确保每个区域都有空间
                      final lineNameFlex = totalLength > 0 
                          ? (lineNameLength * 20 / totalLength).ceil().clamp(1, 10) 
                          : 1;
                      final carNoFlex = totalLength > 0 
                          ? (carNoLength * 20 / totalLength).ceil().clamp(1, 10) 
                          : 1;
                      final escortNameFlex = totalLength > 0 
                          ? (escortNameLength * 20 / totalLength).ceil().clamp(1, 10) 
                          : 1;
                      
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: route,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                          width: double.infinity,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: lineNameFlex,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(2.0),
                                  child: Text(
                                    route['lineName'].toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: carNoFlex,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(2.0),
                                  child: Text(
                                    getPlateNumber(route['carNo'].toString()),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: escortNameFlex,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(2.0),
                                  child: Text(
                                    route['escortName'].toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 客户列表
  Widget customerListWidget() {
    final groupedPoints = _getGroupedPoints();
    
    // 检查是否所有分组都为空
    final hasData = groupedPoints.values.any((points) => points.isNotEmpty);
    
    if (!hasData) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                '暂无客户数据',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        children: groupedPoints.entries.map((entry) {
          if (entry.value.isEmpty) return const SizedBox.shrink();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroupHeader(entry.key.displayName, entry.value.length),
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
    return PageScaffold(
      title: '网点交接',
      showBackButton: true,
      onBackPressed: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      },
      child: lines.isNotEmpty
          ? Column(
              children: [
                headerRouteLine(lines),
                // 客户列表信息
                customerListWidget(),
              ],
            )
          : const Center(child: Text('暂无数据')),
    );
  }
}
