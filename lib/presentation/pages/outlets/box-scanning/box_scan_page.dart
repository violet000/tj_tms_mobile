import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/presentation/state/providers/verify_token_provider.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _service = Service18082();
    _verifyTokenProvider = Provider.of<VerifyTokenProvider>(context, listen: false);
    _getEscortRouteToday();
  }

  Future<void> _getEscortRouteToday() async {
    final String? username = _verifyTokenProvider.getUserData()?['username'] as String?;
    print('username:$username');
    if (username == null) return;
    final dynamic escortRouteToday = await _service.getEscortRouteToday(username);
    setState(() {
      lines = (escortRouteToday['retList'] as List<dynamic>).cast<Map<String, dynamic>>();
      if (lines.isNotEmpty) {
        selectedRoute = lines[0];
      }
    });
  }

  // 获取分组后的网点列表
  Map<String, List<Map<String, dynamic>>> _getGroupedPoints() {
    if (selectedRoute == null) return {};
    
    final List<Map<String, dynamic>> points = (selectedRoute!['points'] as List).cast<Map<String, dynamic>>();
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF5F5F5),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(255, 51, 50, 50),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 175, 214, 234).withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '${count}个',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 30, 30, 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建网点项
  Widget _buildPointItem(Map<String, dynamic> point) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (context) => BoxScanDetailPage(point: point),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF29A8FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF29A8FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point['pointName'].toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      point['address'].toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: point['status'] == 0 ? Color.fromARGB(255, 174, 5, 5) : ( point['status'] == 1 ? Color.fromARGB(255, 4, 133, 4) : Color.fromARGB(255, 16, 95, 222) ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  point['status'] == 0 ? '未交接' : ( point['status'] == 1 ? '已交接' : '交接中' ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('lines:$lines');
    if (lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('网点交接款箱扫描'),
          backgroundColor: const Color(0xFF29A8FF),
          foregroundColor: Colors.white,
        ),
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
      appBar: AppBar(
        title: const Text('网点交接'),
        backgroundColor: const Color(0xFF29A8FF),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF29A8FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.route,
                      color: Color(0xFF29A8FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 150,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButton<Map<String, dynamic>>(
                      value: selectedRoute,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF29A8FF)),
                      items: lines.map((route) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: route,
                          child: Text(
                            route['routeName'].toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (Map<String, dynamic>? newValue) {
                        setState(() {
                          // 根据所选择的线路进行查询当前线路下的网点
                          selectedRoute = newValue;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            // 客户列表信息
            Expanded(
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
            ),
          ],
        ),
      ),
    );
  }
} 