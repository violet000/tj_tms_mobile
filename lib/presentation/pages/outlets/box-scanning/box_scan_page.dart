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
  Map<String, dynamic>? selectedRoute;
  late final Service18082 _service;
  late final VerifyTokenProvider _verifyTokenProvider;

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
    _service = Service18082();
    _verifyTokenProvider =
        Provider.of<VerifyTokenProvider>(context, listen: false);
    _getEscortRouteToday();
  }

  Future<void> _getEscortRouteToday() async {
    final String? username =
        _verifyTokenProvider.getUserData()?['username'] as String?;
    if (username == null) return;
    final dynamic escortRouteToday =
        await _service.getEscortRouteToday(username);
    setState(() {
      lines = (escortRouteToday['retList'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      AppLogger.info('$lines');
      if (lines.isNotEmpty) {
        selectedRoute = lines[0];
      }
    });
  }

  // 获取分组后的网点列表
  Map<String, List<Map<String, dynamic>>> _getGroupedPoints() {
    if (selectedRoute == null) return {};

    final List<Map<String, dynamic>> points =
        (selectedRoute!['points'] as List).cast<Map<String, dynamic>>();
    final Map<String, List<Map<String, dynamic>>> groupedPoints = {
      '出库网点': [],
      '入库网点': [],
    };

    for (var point in points) {
      final int operationType = point['operationType'] as int;
      if (operationType == 0) {
        groupedPoints['出库网点']!.add(point);
      } else if (operationType == 1) {
        groupedPoints['入库网点']!.add(point);
      }
    }

    return groupedPoints;
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

  // 构建网点项
  Widget _buildPointItem(Map<String, dynamic> point) {
    return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => BoxScanDetailPage(point: point),
              ),
            );
          },
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8), color: Colors.white),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(width: 12),
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: const Color(0xFF29A8FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/location_net_point.svg',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 20),
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
                      color: point['status'] == 0 ? const Color.fromARGB(255, 244, 19, 19) : const Color.fromARGB(255, 5, 231, 5),
                      width: 1
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    point['status'] == 0
                        ? '未交接'
                        : (point['status'] == 1 ? '已交接' : '交接中'),
                    style: TextStyle(
                      fontSize: 12,
                      color: point['status'] == 0 ? const Color.fromARGB(255, 244, 19, 19) : const Color.fromARGB(255, 5, 231, 5),
                    ),
                  ),
                )
              ])),
        ));
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<Map<String, dynamic>>(
                    value: selectedRoute,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    items: lines.map((route) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: route,
                        child: Text(
                          route['routeName'].toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
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
              ...entry.value.map((point) => _buildPointItem(point)),
            ],
          );
        }).toList(),
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
