import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/uhf_scan_button.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';

class BoxScanDetailPage extends StatefulWidget {
  final Map<String, dynamic> point;

  const BoxScanDetailPage({
    super.key,
    required this.point,
  });

  @override
  State<BoxScanDetailPage> createState() => _BoxScanDetailPageState();
}

class _BoxScanDetailPageState extends State<BoxScanDetailPage> {
  List<Map<String, dynamic>> items = [];
  bool isScanning = false;
  late final Service18082 _service;
  bool isLoading = true;
  String? error;

  // UHF扫描相关
  final List<String> _uhfScannedTags = [];
  bool _isUHFScanning = false;

  @override
  void initState() {
    super.initState();
    _service = Service18082();
    _getCashBoxList();
  }

  Future<void> _getCashBoxList() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      
      print('widget.point:${widget.point}');
      final dynamic cashBoxList = await _service.getCashBoxList(widget.point['pointCode'].toString());
      setState(() {
        items = (cashBoxList['retList'] as List<dynamic>).cast<Map<String, dynamic>>();
        isLoading = false;
      });
      print('items:$items');
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // 更新款箱状态
  Future<void> _updateCashBoxStatus(String boxCode, int scanStatus) async {
    try {
      await _service.updateCashBoxStatus(boxCode, scanStatus);
      final dynamic cashBoxList = await _service.getCashBoxList(widget.point['pointCode'].toString());
      if (mounted) {
        setState(() {
          items = (cashBoxList['retList'] as List<dynamic>).cast<Map<String, dynamic>>();
          _uhfScannedTags.insert(0, boxCode);
          if (_uhfScannedTags.length > 100) {
            _uhfScannedTags.removeLast();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新款箱状态失败: $e')),
        );
      }
    }
  }

  // UHF扫描
  void _handleUHFTagScanned(String tag) {
    if (!_uhfScannedTags.contains(tag)) {
      if (tag.length > 8) {
        tag = tag.substring(0, 8);
      }
      _updateCashBoxStatus(tag, 1);
    } else {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('款箱已扫描'),
          content: Text('款箱$tag 已扫描'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  void _handleUHFError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('UHF错误: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.point['pointName'].toString()),
          backgroundColor: const Color(0xFF29A8FF),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _getCashBoxList,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.point['pointName'].toString()),
        backgroundColor: const Color(0xFF29A8FF),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 押运线路信息
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '押运线路信息',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '线路编号',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.point['pointCode'].toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '物品总数',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${items.length}个',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // const SizedBox(height: 16),
                // Row(
                //   children: [
                //     Expanded(
                //       child: Container(
                //         padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6, right: 12),
                //         decoration: BoxDecoration(
                //           color: const Color.fromARGB(255, 226, 4, 55).withOpacity(0.1),
                //           borderRadius: BorderRadius.circular(8),
                //         ),
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             const Text(
                //               '未扫描',
                //               style: TextStyle(
                //                 fontSize: 14,
                //                 color: Color(0xFF666666),
                //               ),
                //             ),
                //             const SizedBox(height: 4),
                //             Text(
                //               '${items.where((item) => item['scanStatus'].toString() != '1').length}个',
                //               style: const TextStyle(
                //                 fontSize: 20,
                //                 fontWeight: FontWeight.bold,
                //                 color: Color.fromARGB(255, 226, 4, 55),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ),
                //     const SizedBox(width: 16),
                //     Expanded(
                //       child: Container(
                //         padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6, right: 12),
                //         decoration: BoxDecoration(
                //           color: const Color(0xFF52C41A).withOpacity(0.1),
                //           borderRadius: BorderRadius.circular(8),
                //         ),
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             const Text(
                //               '已扫描',
                //               style: TextStyle(
                //                 fontSize: 14,
                //                 color: Color(0xFF666666),
                //               ),
                //             ),
                //             const SizedBox(height: 4),
                //             Text(
                //               '${items.where((item) => item['scanStatus'].toString() == '1').length}个',
                //               style: const TextStyle(
                //                 fontSize: 20,
                //                 fontWeight: FontWeight.bold,
                //                 color: Color(0xFF52C41A),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(top: 5, bottom: 5, left: 8),
            child: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '箱子列表',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 51, 50, 50),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () {
                    final TextEditingController textController = TextEditingController();
                    showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('手工匹配'),
                        content: TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            hintText: '请输入款箱编号',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _handleUHFTagScanned(value);
                              Navigator.pop(context);
                            }
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (textController.text.isNotEmpty) {
                                _handleUHFTagScanned(textController.text);
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                  label: const Text(
                    '手工匹配',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 3, 145, 202),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    // backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 箱子列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 10),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  // margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    // borderRadius: BorderRadius.circular(12),
                    border: index + 1 == items.length ? null : const Border(
                      bottom: BorderSide(color: const Color(0xFFEEEEEE), width: 1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF29A8FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
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
                                item['boxCode'].toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          child: item['scanStatus'].toString() == '1'
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF29A8FF),
                                  size: 24,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 底部按钮
          Container(
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
                  child: UHFScanButton(
                    buttonWidth: double.infinity,
                    buttonHeight: 48,
                    onTagScanned: _handleUHFTagScanned,
                    onError: _handleUHFError,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 用于实现交接功能
                      if (items.where((item) => item['scanStatus'].toString() == '0').length > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('存在未扫描的款箱，请先完成扫描'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Color.fromARGB(255, 219, 3, 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('确认交接'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF52C41A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 在页面销毁时停止UHF扫描
    if (_isUHFScanning) {
      _isUHFScanning = false;
    }
    super.dispose();
  }
} 