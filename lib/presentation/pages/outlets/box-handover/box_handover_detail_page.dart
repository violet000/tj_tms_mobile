import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/uhf_scan_button.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/blue_polygon_background.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/blank_item_card.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';
import 'package:tj_tms_mobile/presentation/state/providers/line_info_provider.dart';
import 'package:tj_tms_mobile/presentation/state/providers/box_handover_provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/auth_dialog.dart';
import 'package:tj_tms_mobile/core/utils/cashbox_scan_utils.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/confirm_dialog.dart';

class BoxHandoverDetailPage extends StatefulWidget {
  const BoxHandoverDetailPage({super.key});

  @override
  State<BoxHandoverDetailPage> createState() => _BoxHandoverDetailPageState();
}

class _BoxHandoverDetailPageState extends State<BoxHandoverDetailPage> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> lines = [];
  Map<String, dynamic> selectedRoute = <String, dynamic>{};
  bool isScanning = false;
  Service18082? _service;
  bool isLoading = false;
  String? error;

  // UHF扫描相关
  final List<String> _uhfScannedTags = [];
  bool _isUHFScanning = false;

  // 存储扫描的款箱信息
  final List<Map<String, String>> _scannedBoxes = [];

  // 存储手工匹配弹窗中用户选中的款箱
  List<Map<String, dynamic>> _selectedManualBoxes = [];

  // 存储手工匹配的款箱代码（用于标记显示）
  final List<String> unrecognizedBox = [];

  // 认证相关
  bool _isAuthenticated = false;
  bool _isAuthDialogShown = false;
  String? isConsistent = null;
  String? _authenticatedUsername;
  String? _authenticatedVehiclePlateNumber;

  @override
  void initState() {
    super.initState();
    _initializeService();
    final boxHandoverProvider =
        Provider.of<BoxHandoverProvider>(context, listen: false);
    items = boxHandoverProvider.boxItems;
    selectedRoute = boxHandoverProvider.selectedRoute;

    // 页面加载完成后显示认证弹框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAuthDialog();
    });
  }

  Future<void> _initializeService() async {
    _service = await Service18082.create();
  }

  /// 显示认证弹框
  void _showAuthDialog() {
    if (_isAuthDialogShown) return;

    _isAuthDialogShown = true;

    // 获取线路信息
    final expectedVehicleRfid = selectedRoute['carNo']?.toString();
    final expectedPersonRfid = selectedRoute['escortName']?.toString();

    AuthDialog.show(
      context: context,
      title: '身份认证',
      vehicleRfidExpected: expectedVehicleRfid,
      personRfidExpected: expectedPersonRfid,
      onCancel: () {
        // 认证取消，返回上一页
        Navigator.of(context).pop();
      },
      onComplete: (result) {
        if (result.success) {
          setState(() {
            _isAuthenticated = true;
            isConsistent = result.errorMessage ?? '';
            _authenticatedUsername = result.username?.trim();
            _authenticatedVehiclePlateNumber = result.vehiclePlateNumber?.trim();
          });
        } else {
          // 可以选择返回上一页或重新认证
          Navigator.of(context).pop();
        }
      },
    );
  }

  // 自定义内容体的头部 - 添加线路、车、押运员信息
  Widget customBodyHeader(List<Map<String, dynamic>> items) {
    return Consumer<LineInfoProvider>(
      builder: (context, lineInfoProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: Colors.transparent,
          child: BluePolygonBackground(
            width: 900,
            height: 150,
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
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
                                    selectedRoute['lineName'].toString() ??
                                        '暂无数据',
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
                          ),
                          const SizedBox(height: 4),
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
                                    "车辆信息",
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
                                    selectedRoute['carNo'].toString() ?? '暂无数据',
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
                          ),
                          const SizedBox(height: 4),
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
                                    "押运员信息",
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
                                    selectedRoute['escortName'].toString() ??
                                        '暂无数据',
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
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 16, right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: manualMatch()),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: UHFScanButton(
                                buttonWidth: double.infinity,
                                buttonHeight: 28,
                                onTagScanned: _handleUHFTagScanned,
                                onError: _handleUHFError,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // 款箱列表
  Widget cashBoxList(List<Map<String, dynamic>> items) {
    print('cashBoxList items: $items');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "物品总数",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                "${items.length}个",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF29A8FF),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
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
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, top: 2, bottom: 2),
                  color: Colors.transparent,
                  child: BlankItemCard(
                    width: double.infinity,
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 30),
                        SvgPicture.asset(
                          "assets/icons/cashbox_package.svg",
                          fit: BoxFit.contain,
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 25),
                        Expanded(
                          child: Text(
                            item['boxCode'] == null
                                ? ''
                                : item['boxCode'].toString().split('-').first,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: SvgPicture.asset(
                              item['scanStatus'] == 1
                                  ? "assets/icons/check_error.svg"
                                  : "assets/icons/check_success.svg",
                              fit: BoxFit.cover,
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 手工匹配控件
  Widget manualMatch() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          List<Map<String, dynamic>> unscannedItems =
              items.where((item) => item['scanStatus'] == 1).toList();

          if (unscannedItems.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('没有可匹配的未扫描款箱'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          _selectedManualBoxes = [];

          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setStateInDialog) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.height * 0.90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          // 标题栏
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFF29A8FF),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.link,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    '手工匹配',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_selectedManualBoxes.length}/${unscannedItems.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 内容区域
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // 操作栏
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE9ECEF),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: const Color(0xFF29A8FF),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          '选择操作',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: () {
                                            setStateInDialog(() {
                                              final bool allSelected =
                                                  _selectedManualBoxes.length ==
                                                      unscannedItems.length;
                                              if (allSelected) {
                                                _selectedManualBoxes = [];
                                              } else {
                                                _selectedManualBoxes = List<
                                                        Map<String,
                                                            dynamic>>.from(
                                                    unscannedItems);
                                              }
                                            });
                                          },
                                          icon: Icon(
                                            _selectedManualBoxes.length ==
                                                    unscannedItems.length
                                                ? Icons.check_box_outline_blank
                                                : Icons.check_box,
                                            color: const Color(0xFF29A8FF),
                                            size: 16,
                                          ),
                                          label: Text(
                                            _selectedManualBoxes.length ==
                                                    unscannedItems.length
                                                ? '取消全选'
                                                : '全选',
                                            style: const TextStyle(
                                              color: Color(0xFF29A8FF),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // 款箱列表
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F9FA),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFE9ECEF),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          // 列表标题
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFE9ECEF),
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(8),
                                                topRight: Radius.circular(8),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.inventory_2_outlined,
                                                  color: Color(0xFF29A8FF),
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  '待匹配款箱',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF333333),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '共 ${unscannedItems.length} 个',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF666666),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // 列表内容
                                          Expanded(
                                            child: unscannedItems.isEmpty
                                                ? Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.inbox_outlined,
                                                          size: 32,
                                                          color:
                                                              Colors.grey[400],
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          '暂无待匹配款箱',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : ListView.separated(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    itemCount:
                                                        unscannedItems.length,
                                                    separatorBuilder: (_, __) =>
                                                        const SizedBox(
                                                            height: 4),
                                                    itemBuilder:
                                                        (context, index) {
                                                      final box =
                                                          unscannedItems[index];
                                                      final bool isSelected =
                                                          _selectedManualBoxes
                                                              .any(
                                                        (selectedBox) =>
                                                            selectedBox[
                                                                'boxCode'] ==
                                                            box['boxCode'],
                                                      );
                                                      return Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isSelected
                                                              ? const Color(
                                                                  0xFFE3F2FD)
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? const Color(
                                                                    0xFF29A8FF)
                                                                : const Color(
                                                                    0xFFE0E0E0),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: ListTile(
                                                          dense: true,
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 12,
                                                            vertical: 4,
                                                          ),
                                                          leading: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(6),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: isSelected
                                                                  ? const Color(
                                                                      0xFF29A8FF)
                                                                  : const Color(
                                                                      0xFFF5F5F5),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                            ),
                                                            child: Icon(
                                                              Icons.qr_code,
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : const Color(
                                                                      0xFF666666),
                                                              size: 16,
                                                            ),
                                                          ),
                                                          title: Text(
                                                            box['boxCode'] ==
                                                                    null
                                                                ? ''
                                                                : box['boxCode']
                                                                    .toString()
                                                                    .split('-')
                                                                    .first,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: isSelected
                                                                  ? const Color(
                                                                      0xFF29A8FF)
                                                                  : const Color(
                                                                      0xFF333333),
                                                            ),
                                                          ),
                                                          subtitle: Text(
                                                            '款箱编号',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: isSelected
                                                                  ? const Color(
                                                                          0xFF29A8FF)
                                                                      .withOpacity(
                                                                          0.7)
                                                                  : const Color(
                                                                      0xFF999999),
                                                            ),
                                                          ),
                                                          trailing: Container(
                                                            width: 20,
                                                            height: 20,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: isSelected
                                                                  ? const Color(
                                                                      0xFF29A8FF)
                                                                  : Colors
                                                                      .transparent,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              border:
                                                                  Border.all(
                                                                color: isSelected
                                                                    ? const Color(
                                                                        0xFF29A8FF)
                                                                    : const Color(
                                                                        0xFFCCCCCC),
                                                                width: 1.5,
                                                              ),
                                                            ),
                                                            child: isSelected
                                                                ? const Icon(
                                                                    Icons.check,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 12,
                                                                  )
                                                                : null,
                                                          ),
                                                          onTap: () {
                                                            setStateInDialog(
                                                                () {
                                                              if (isSelected) {
                                                                _selectedManualBoxes
                                                                    .removeWhere(
                                                                  (selectedBox) =>
                                                                      selectedBox[
                                                                          'boxCode'] ==
                                                                      box['boxCode'],
                                                                );
                                                              } else {
                                                                if (!_selectedManualBoxes.any(
                                                                    (selected) =>
                                                                        selected[
                                                                            'boxCode'] ==
                                                                        box['boxCode'])) {
                                                                  _selectedManualBoxes
                                                                      .add(box);
                                                                }
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 底部按钮
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              color: Color(0xFFF8F9FA),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _selectedManualBoxes = [];
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF666666),
                                      side: const BorderSide(
                                          color: Color(0xFFDDDDDD)),
                                      minimumSize: const Size(0, 40),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.close, size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          '取消',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_selectedManualBoxes.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: const [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  '请选择至少一个款箱进行匹配',
                                                  style:
                                                      TextStyle(fontSize: 13),
                                                ),
                                              ],
                                            ),
                                            backgroundColor:
                                                const Color(0xFFFF6B35),
                                            duration:
                                                const Duration(seconds: 2),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final List<Map<String, dynamic>>
                                          selectedSnapshot =
                                          List<Map<String, dynamic>>.from(
                                              _selectedManualBoxes);
                                      for (var box in selectedSnapshot) {
                                        final String boxCodeFront =
                                            box['boxCode'] == null
                                                ? ''
                                                : box['boxCode']
                                                    .toString()
                                                    .split('-')
                                                    .first;
                                        if (boxCodeFront.isNotEmpty) {
                                          // 添加到手工匹配数组
                                          if (!unrecognizedBox.contains(boxCodeFront)) {
                                            unrecognizedBox.add(boxCodeFront);
                                          }
                                          _updateCashBoxStatus(boxCodeFront, 0);
                                        }
                                      }
                                      Navigator.pop(context);
                                      setState(() {
                                        _selectedManualBoxes = [];
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: const Color(0xFF29A8FF),
                                      minimumSize: const Size(0, 40),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      elevation: 1,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.check_circle_outline,
                                            size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          '确认匹配',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
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
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                "手工匹配",
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
            child: ElevatedButton.icon(
              onPressed: () async {
                if (items
                    .where((item) => item['scanStatus'].toString() == '1')
                    .isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('存在未扫描的款箱，请先完成扫描'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Color.fromARGB(255, 219, 3, 3),
                    ),
                  );
                } else {
                  final boxHandoverProvider =
                      Provider.of<BoxHandoverProvider>(context, listen: false);
                  final List<Map<String, dynamic>> selectedPoints =
                      boxHandoverProvider.selectedPoints;
                  final List<String> orgNos = selectedPoints
                      .map((p) => p['orgNo']?.toString())
                      .whereType<String>()
                      .toList();
                  Navigator.pushNamed(
                    context,
                    '/outlets/box-handover-verify',
                    arguments: <String, dynamic>{
                      'isConsistent': isConsistent,
                      'orgNo': orgNos[0],
                      'unrecognizedBox': unrecognizedBox.join(',').toString(),
                      'authUsername': _authenticatedUsername,
                      'vehiclePlateNumber': _authenticatedVehiclePlateNumber,
                    },
                  );
                }
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('确认交接'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 2, 112, 215),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 更新款箱状态
  Future<void> _updateCashBoxStatus(String boxCode, int scanStatus) async {
    final result = CashBoxScanUtils.updateCashBoxStatus(
      items: items,
      boxCode: boxCode,
      scanStatus: scanStatus,
      uhfScannedTags: _uhfScannedTags,
      scannedBoxes: _scannedBoxes,
    );

    if (result['success'] as bool) {
      setState(() {
        _uhfScannedTags.clear();
        _uhfScannedTags.addAll(result['uhfScannedTags'] as List<String>);
        _scannedBoxes.clear();
        _scannedBoxes
            .addAll(result['scannedBoxes'] as List<Map<String, String>>);
      });
    } else {
      if (mounted) {
        CashBoxScanUtils.showError(context, result['message'] as String);
      }
    }
  }

  // UHF扫描和手工匹配的统一处理函数
  void _handleUHFTagScanned(String tag) {
    final result = CashBoxScanUtils.handleUHFTagScanned(
      items: items,
      tag: tag,
      uhfScannedTags: _uhfScannedTags,
      scannedBoxes: _scannedBoxes,
    );

    if (result['success'] as bool) {
      setState(() {
        _uhfScannedTags.clear();
        _uhfScannedTags.addAll(result['uhfScannedTags'] as List<String>);
        _scannedBoxes.clear();
        _scannedBoxes
            .addAll(result['scannedBoxes'] as List<Map<String, String>>);
      });
    }
  }

  // 取消匹配
  void _onUnmatch(Map<String, dynamic> item) {
    final result = CashBoxScanUtils.unmatchCashBox(
      item: item,
      items: items,
      uhfScannedTags: _uhfScannedTags,
      scannedBoxes: _scannedBoxes,
    );

    if (result['success'] as bool) {
      // 获取款箱代码
      final String boxCode = item['boxCode'] == null
          ? ''
          : item['boxCode'].toString().split('-').first;
      
      // 如果是手工匹配的款箱，从数组中移除
      if (boxCode.isNotEmpty && unrecognizedBox.contains(boxCode)) {
        unrecognizedBox.remove(boxCode);
      }
      
      setState(() {
        _uhfScannedTags.clear();
        _uhfScannedTags.addAll(result['uhfScannedTags'] as List<String>);
        _scannedBoxes.clear();
        _scannedBoxes
            .addAll(result['scannedBoxes'] as List<Map<String, String>>);
      });
    } else {
      if (mounted) {
        CashBoxScanUtils.showError(context, result['message'] as String);
      }
    }
  }

  void _handleUHFError(String error) {
    CashBoxScanUtils.showUHFError(context, error);
  }

  /// 构建认证等待状态的Widget
  Widget _buildAuthPendingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.security,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          const Text(
            '正在进行身份认证...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '请完成身份认证后继续操作',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              _isAuthDialogShown = false;
              _showAuthDialog();
            },
            child: const Text('重新认证'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BoxHandoverProvider>(
      builder: (context, boxHandoverProvider, child) {
        // 写入全局线路信息（与 box_scan_detail_page 保持一致）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final lineInfoProvider =
              Provider.of<LineInfoProvider>(context, listen: false);
          final String lineName =
              boxHandoverProvider.selectedRoute['lineName']?.toString() ?? '';
          final String escortName =
              boxHandoverProvider.selectedRoute['escortName']?.toString() ?? '';
          final String carNo =
              boxHandoverProvider.selectedRoute['carNo']?.toString() ?? '';
          // 从选中的网点中取一个名称作为展示
          final String orgName = (boxHandoverProvider.selectedPoints.isNotEmpty)
              ? (boxHandoverProvider.selectedPoints.first['orgName']
                      ?.toString() ??
                  '')
              : '';
          // 写入全局线路信息
          final Map<String, dynamic> lineInfo = <String, dynamic>{
            'lineName': lineName,
            'escortName': escortName,
            'carNo': carNo,
            'orgName': orgName,
            'items': items,
          };
          lineInfoProvider.setLineInfo(lineInfo);
        });

        return PageScaffold(
          title: boxHandoverProvider.selectedRoute['lineName'].toString() ??
              '暂无数据',
          showBackButton: true,
          onBackPressed: () {
            showDialog<void>(
              context: context,
              builder: (ctx) => ConfirmDialog(
                title: '确认返回',
                content: '是否返回上一步？',
                onConfirm: () {
                  Navigator.pop(context);
                },
              ),
            );
          },
          child: Column(
            children: [
              customBodyHeader(items),
              Expanded(
                child: _isAuthenticated
                    ? cashBoxList(items)
                    : _buildAuthPendingWidget(),
              ),
              if (_isAuthenticated) footerButton(items),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    if (_isUHFScanning) {
      _isUHFScanning = false;
    }
    super.dispose();
  }
}
