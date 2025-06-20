import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/uhf_scan_button.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-scanning/box_scan_verify_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/blue_polygon_background.dart';

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

  // 自定义appBar
  PreferredSizeWidget appCustomBar(BuildContext context) {
    return AppBar(
      title: Text(
        '${widget.point['pointName'].toString()}款箱扫描',
        textAlign: TextAlign.left,
        style: const TextStyle(
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

  // 款箱列表
  Widget cashBoxList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 10),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Slidable(
          key: ValueKey<String>(item['boxCode'].toString()),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (context) {
                  _onUnmatch(item);
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.cancel,
                label: '取消匹配',
              ),
            ],
          ),
          child: Container(
            // margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              // borderRadius: BorderRadius.circular(12),
              border: index + 1 == items.length
                  ? null
                  : const Border(
                      bottom:
                          BorderSide(color: const Color(0xFFEEEEEE), width: 1),
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
          ),
        );
      },
    );
  }

  // 底部按钮控件
  Widget footerButton(List<Map<String, dynamic>> items) {
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
              onPressed: () async {
                // 用于实现交接功能
                if (items
                        .where((item) => item['scanStatus'].toString() == '0')
                        .length >
                    0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('存在未扫描的款箱，请先完成扫描'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Color.fromARGB(255, 219, 3, 3),
                    ),
                  );
                } else {
                  await _service.handoverCashBox(
                      widget.point['pointCode'].toString(),
                      items
                          .map<String>((item) => item['boxCode'].toString())
                          .toList());
                  if (mounted) {
                    Navigator.push<bool>(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (context) => BoxScanVerifyPage(
                          point: widget.point,
                          boxCodes: items
                              .map<String>((item) => item['boxCode'].toString())
                              .toList(),
                        ),
                      ),
                    );
                  }
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
    );
  }

  // 手工匹配按钮以及按钮弹窗
  Widget manualMatch() {
    return TextButton.icon(
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
    );
  }

  Future<void> _getCashBoxList() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      final dynamic cashBoxList =
          await _service.getCashBoxList(widget.point['pointCode'].toString());
      setState(() {
        items = (cashBoxList['retList'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        isLoading = false;
      });
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
      final dynamic cashBoxList =
          await _service.getCashBoxList(widget.point['pointCode'].toString());
      if (mounted) {
        setState(() {
          items = (cashBoxList['retList'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
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

  // 取消匹配
  void _onUnmatch(Map<String, dynamic> item) {
    _uhfScannedTags.remove(item['boxCode'].toString());
    _updateCashBoxStatus(item['boxCode'].toString(), 0);
  }

  void _handleUHFError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('UHF错误: $error')),
      );
    }
  }

  // 自定义内容体的头部
  Widget customBodyHeader() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.transparent,
      child: BluePolygonBackground(
          width: 900,
          height: 150,
          child: Column(
            children: [
              // 顶部信息区和下方内容区完整布局
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部信息行
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text(
                              "物品总数",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "6个",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: const [
                            Text(
                              "线路名称",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "线路1",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 下方白色内容区
                  Container(
                    margin: const EdgeInsets.only(left: 16, right: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 24),
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
                        // 左侧按钮
                        Expanded(
                          child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              // 手工匹配款箱点击事件
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/manual_input_cashbox.svg',
                                    width: 18,
                                    height: 18,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "手工录入",
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 2, 121, 218),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                        // 右侧按钮
                        Expanded(
                            child: Material(
                                color: Colors.transparent,
                                child: UHFScanButton(
                                  buttonWidth: double.infinity,
                                  buttonHeight: 48,
                                  onTagScanned: _handleUHFTagScanned,
                                  onError: _handleUHFError,
                                ))),
                      ],
                    ),
                  ),
                ],
              )
            ],
          )),
    );
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
        appBar: appCustomBar(context),
        body: Column(
          children: [
            // 内容体的头部 -> 押运线路信息
            customBodyHeader()
          ],
        ));
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
