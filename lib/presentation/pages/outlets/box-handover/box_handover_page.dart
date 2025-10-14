import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:tj_tms_mobile/presentation/state/providers/verify_token_provider.dart';
import 'package:tj_tms_mobile/presentation/state/providers/box_handover_provider.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/blue_polygon_background.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:tj_tms_mobile/core/constants/constant.dart';

class BoxHandoverPage extends StatefulWidget {
  const BoxHandoverPage({super.key});

  @override
  State<BoxHandoverPage> createState() => _BoxHandoverPageState();
}

class _BoxHandoverPageState extends State<BoxHandoverPage> {
  List<Map<String, dynamic>> lines = [];
  List<String> lineNoArray = [];
  Map<String, dynamic>? selectedRoute;
  Service18082? _service;
  late final VerifyTokenProvider _verifyTokenProvider;
  late final BoxHandoverProvider _boxHandoverProvider;
  Future<List<Map<String, dynamic>>>? _linesFuture;
  int? _mode;

  // 添加选中状态管理
  Set<String> selectedDeliverPoints = {}; // 选中的出库网点 orgNo
  Set<String> selectedReceivePoints = {}; // 选中的入库网点 orgNo
  bool isDeliverAllSelected = false; // 出库全选状态
  bool isReceiveAllSelected = false; // 入库全选状态
  bool isDeliverEnabled = true; // 出库是否可用
  bool isReceiveEnabled = true; // 入库是否可用

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
    _boxHandoverProvider =
        Provider.of<BoxHandoverProvider>(context, listen: false);
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
      // 统一处理可能发生的任何错误
      AppLogger.error('获取或解析线路数据时发生错误', e, s);
      // 可以在这里弹出一个对话框告诉用户加载失败
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
              'operationType': InOutStatus.outlet.code, // 标记为出库
              // 补充网点显示所需的字段
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
      '出库网点': deliverPointsMap.values.toList(),
      '入库网点': receivePointsMap.values.toList(),
    };
  }

  // 处理出库全选
  void _handleDeliverAllSelected(bool? value) {
    if (value == null) return;

    setState(() {
      if (value) {
        // 全选出库网点
        final groupedPoints = _getGroupedPoints();
        final deliverPoints = groupedPoints['出库网点'] ?? [];
        final selectableDeliverOrgNos = deliverPoints
            .where((point) => point['status'] != true)
            .map((point) => point['orgNo']?.toString())
            .where((orgNo) => orgNo != null && orgNo.isNotEmpty)
            .cast<String>()
            .toSet();
        selectedDeliverPoints = selectableDeliverOrgNos;
        isDeliverAllSelected =
            selectedDeliverPoints.length == selectableDeliverOrgNos.length;

        // 禁用入库
        isReceiveEnabled = false;
        isReceiveAllSelected = false;
        selectedReceivePoints.clear();
      } else {
        // 取消全选出库网点
        selectedDeliverPoints.clear();
        isDeliverAllSelected = false;

        // 启用入库
        isReceiveEnabled = true;
      }
    });
  }

  // 处理入库全选
  void _handleReceiveAllSelected(bool? value) {
    if (value == null) return;

    setState(() {
      if (value) {
        // 全选入库网点
        final groupedPoints = _getGroupedPoints();
        final receivePoints = groupedPoints['入库网点'] ?? [];
        final selectableReceiveOrgNos = receivePoints
            .where((point) => point['status'] != true)
            .map((point) => point['orgNo']?.toString())
            .where((orgNo) => orgNo != null && orgNo.isNotEmpty)
            .cast<String>()
            .toSet();
        selectedReceivePoints = selectableReceiveOrgNos;
        isReceiveAllSelected =
            selectedReceivePoints.length == selectableReceiveOrgNos.length;

        // 禁用出库
        isDeliverEnabled = false;
        isDeliverAllSelected = false;
        selectedDeliverPoints.clear();
      } else {
        // 取消全选入库网点
        selectedReceivePoints.clear();
        isReceiveAllSelected = false;

        // 启用出库
        isDeliverEnabled = true;
      }
    });
  }

  // 处理单个网点选中
  void _handlePointSelected(String orgNo, bool isDeliver, bool? value) {
    if (value == null) return;

    setState(() {
      if (isDeliver) {
        if (value) {
          selectedDeliverPoints.add(orgNo);
          // 检查是否全选
          final groupedPoints = _getGroupedPoints();
          final deliverPoints = groupedPoints['出库网点'] ?? [];
          final allDeliverOrgNos = deliverPoints
              .where((point) => point['status'] != true)
              .map((point) => point['orgNo']?.toString())
              .where((orgNo) => orgNo != null && orgNo.isNotEmpty)
              .cast<String>()
              .toSet();
          isDeliverAllSelected =
              selectedDeliverPoints.length == allDeliverOrgNos.length;

          // 禁用入库
          isReceiveEnabled = false;
          isReceiveAllSelected = false;
          selectedReceivePoints.clear();
        } else {
          selectedDeliverPoints.remove(orgNo);
          isDeliverAllSelected = false;

          // 如果没有选中的出库网点，启用入库
          if (selectedDeliverPoints.isEmpty) {
            isReceiveEnabled = true;
          }
        }
      } else {
        if (value) {
          selectedReceivePoints.add(orgNo);
          // 检查是否全选
          final groupedPoints = _getGroupedPoints();
          final receivePoints = groupedPoints['入库网点'] ?? [];
          final allReceiveOrgNos = receivePoints
              .where((point) => point['status'] != true)
              .map((point) => point['orgNo']?.toString())
              .where((orgNo) => orgNo != null && orgNo.isNotEmpty)
              .cast<String>()
              .toSet();
          isReceiveAllSelected =
              selectedReceivePoints.length == allReceiveOrgNos.length;

          // 禁用出库
          isDeliverEnabled = false;
          isDeliverAllSelected = false;
          selectedDeliverPoints.clear();
        } else {
          selectedReceivePoints.remove(orgNo);
          isReceiveAllSelected = false;

          // 如果没有选中的入库网点，启用出库
          if (selectedReceivePoints.isEmpty) {
            isDeliverEnabled = true;
          }
        }
      }
    });
  }

  // 构建网点项
  Widget _buildPointItem(Map<String, dynamic> point) {
    final String? orgNo = point['orgNo']?.toString();
    final bool isDeliver = point['operationType'] == InOutStatus.outlet.code;
    final bool isSelected = isDeliver
        ? selectedDeliverPoints.contains(orgNo)
        : selectedReceivePoints.contains(orgNo);
    final bool isCompleted = point['status'] == true;
    final bool isEnabled =
        (isDeliver ? isDeliverEnabled : isReceiveEnabled) && !isCompleted;

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
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
              // 网点复选框
              if (orgNo != null && orgNo.isNotEmpty)
                MouseRegion(
                  cursor: isEnabled
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    onTap: isEnabled
                        ? () =>
                            _handlePointSelected(orgNo, isDeliver, !isSelected)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF29A8FF)
                            : Colors.transparent,
                        border: Border.all(
                          color: isEnabled
                              ? (isSelected
                                  ? const Color(0xFF29A8FF)
                                  : const Color(0xFFCCCCCC))
                              : const Color(0xFFCCCCCC).withOpacity(0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF29A8FF).withOpacity(0.3),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                key: ValueKey('checked'),
                                size: 12,
                                color: Colors.white,
                              )
                            : const SizedBox.shrink(key: ValueKey('unchecked')),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isEnabled
                            ? const Color.fromARGB(255, 69, 68, 68)
                            : const Color.fromARGB(255, 69, 68, 68)
                                .withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      point['address'].toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isEnabled
                            ? const Color.fromARGB(255, 121, 120, 120)
                            : const Color.fromARGB(255, 121, 120, 120)
                                .withOpacity(0.5),
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
                  child: DropdownButton<Map<String, dynamic>>(
                    value: selectedRoute,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    underline: const SizedBox(),
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                    selectedItemBuilder: (BuildContext context) {
                      return lines.map<Widget>((Map<String, dynamic> route) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                  route['carNo'].toString(),
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
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: route,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  route['lineName'].toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  route['carNo'].toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
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
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
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
                        // 重置选中状态
                        selectedDeliverPoints.clear();
                        selectedReceivePoints.clear();
                        isDeliverAllSelected = false;
                        isReceiveAllSelected = false;
                        isDeliverEnabled = true;
                        isReceiveEnabled = true;
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
    final bool isDeliver = title == '出库网点';
    final bool isAllSelected =
        isDeliver ? isDeliverAllSelected : isReceiveAllSelected;
    final bool isEnabled = isDeliver ? isDeliverEnabled : isReceiveEnabled;

    return Container(
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
                // 全选复选框
                MouseRegion(
                  cursor: isEnabled
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    onTap: isEnabled
                        ? () {
                            if (isDeliver) {
                              _handleDeliverAllSelected(!isAllSelected);
                            } else {
                              _handleReceiveAllSelected(!isAllSelected);
                            }
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color:
                            isAllSelected ? Colors.white : Colors.transparent,
                        border: Border.all(
                          color: isEnabled
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: isAllSelected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: isAllSelected
                            ? const Icon(
                                Icons.check,
                                key: ValueKey('checked'),
                                size: 14,
                                color: Color(0xffB8C8E0),
                              )
                            : const SizedBox.shrink(key: ValueKey('unchecked')),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$title:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isEnabled
                        ? const Color.fromARGB(255, 255, 255, 255)
                        : const Color.fromARGB(255, 255, 255, 255)
                            .withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count个',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isEnabled
                        ? const Color.fromARGB(255, 255, 255, 255)
                        : const Color.fromARGB(255, 255, 255, 255)
                            .withOpacity(0.5),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // 获取选中的网点数据
  List<Map<String, dynamic>> _getSelectedPointsData() {
    final groupedPoints = _getGroupedPoints();
    final List<Map<String, dynamic>> selectedPoints = <Map<String, dynamic>>[];

    // 获取选中的出库网点
    for (final point in groupedPoints['出库网点'] ?? <Map<String, dynamic>>[]) {
      if (point is Map<String, dynamic>) {
        final String? orgNo = point['orgNo']?.toString();
        if (orgNo != null && selectedDeliverPoints.contains(orgNo)) {
          selectedPoints.add(point);
        }
      }
    }

    // 获取选中的入库网点
    for (final point in groupedPoints['入库网点'] ?? <Map<String, dynamic>>[]) {
      if (point is Map<String, dynamic>) {
        final String? orgNo = point['orgNo']?.toString();
        if (orgNo != null && selectedReceivePoints.contains(orgNo)) {
          selectedPoints.add(point);
        }
      }
    }

    return selectedPoints;
  }

  // 处理选中的网点数据
  void _processSelectedPoints() {
    final selectedPoints = _getSelectedPointsData();
    _executeProcessing(selectedPoints);
  }

  // 执行处理逻辑
  Future<void> _executeProcessing(
      List<Map<String, dynamic>> selectedPoints) async {
    try {
      EasyLoading.show(
        status: '处理中...',
        maskType: EasyLoadingMaskType.black,
      );
      final boxItems = await _processPointsData(selectedPoints);
      // 将数据存入provider
      _boxHandoverProvider.setBoxHandoverData(boxItems);
      _boxHandoverProvider.setSelectedPoints(selectedPoints);
      _boxHandoverProvider.setSelectedRoute(selectedRoute as Map<String, dynamic>);
      _boxHandoverProvider.setOperationType(isReceiveEnabled ? InOutStatus.inlet.code.toString() : InOutStatus.outlet.code.toString());
      if (boxItems.isNotEmpty) {
        Navigator.pushNamed(context, '/outlets/box-handover-detail');
      }
    } catch (e) {
      _boxHandoverProvider.setErrorMessage(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('数据处理失败：${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: const Color.fromARGB(255, 219, 3, 3),
        ),
      );
    } finally {
      _boxHandoverProvider.setProcessing(false);
      EasyLoading.dismiss();
    }
  }

  // 处理网点数据的具体逻辑
  Future<Map<String, dynamic>> _processPointsData(
      List<Map<String, dynamic>> selectedPoints) async {
    Map<String, dynamic> boxCollection = <String, dynamic>{
      'boxItems': <Map<String, dynamic>>[],
      'implBoxDetails': <Map<String, dynamic>>[],
    };

    for (var point in selectedPoints) {
      final List<dynamic>? implBoxDetail =
          point['implBoxDetail'] as List<dynamic>?;
      if (implBoxDetail != null) {
        for (var impl in implBoxDetail) {
          boxCollection['implBoxDetails']
              ?.add(<String, dynamic>{'implNo': impl['implNo']});
          if (impl is Map<String, dynamic>) {
            final List<dynamic>? boxDetail =
                impl['boxDetail'] as List<dynamic>?;
            if (boxDetail != null) {
              for (var box in boxDetail) {
                if (box is Map<String, dynamic>) {
                  boxCollection['boxItems']?.add(<String, dynamic>{
                    'boxCode': box['boxNo'],
                    'scanStatus': int.parse(box['boxHandStatus'].toString()),
                  });
                }
              }
            }
          }
        }
      }
    }
    return boxCollection;
  }

  // 底部按钮控件
  Widget footerButton() {
    final selectedPoints = _getSelectedPointsData();
    final bool hasSelection = selectedPoints.isNotEmpty;

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
              onPressed: hasSelection ? _processSelectedPoints : null,
              icon: const Icon(Icons.arrow_circle_right_outlined),
              label:
                  Text(hasSelection ? '下一步 (${selectedPoints.length})' : '下一步'),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasSelection
                    ? const Color.fromARGB(255, 2, 112, 215)
                    : const Color.fromARGB(255, 200, 200, 200),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '金库交接',
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
                // 底部按钮
                footerButton(),
              ],
            )
          : const Center(child: Text('暂无数据')),
    );
  }
}
