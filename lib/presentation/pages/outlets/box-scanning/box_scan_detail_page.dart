import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/uhf_scan_button.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-scanning/box_scan_verify_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/blue_polygon_background.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/blank_item_card.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';

class BoxScanDetailPage extends StatefulWidget {
  final Map<String, dynamic> point;
  final List<Map<String, dynamic>> boxItems; // 新增款箱数据参数
  final List<Map<String, dynamic>> lines;

  const BoxScanDetailPage({
    super.key,
    required this.point,
    required this.boxItems,
    required this.lines, // 新增参数
  });

  @override
  State<BoxScanDetailPage> createState() => _BoxScanDetailPageState();
}

class _BoxScanDetailPageState extends State<BoxScanDetailPage> {
  List<Map<String, dynamic>> items = [];
  bool isScanning = false;
  Service18082? _service;
  bool isLoading = false; // 不再需要加载状态，因为数据已经在父页面获取
  String? error;

  // UHF扫描相关
  final List<String> _uhfScannedTags = [];
  bool _isUHFScanning = false;

  // 新增：存储扫描的款箱信息
  final List<Map<String, String>> _scannedBoxes = [];

  // 新增：存储手工匹配弹窗中用户选中的款箱
  List<Map<String, dynamic>> _selectedManualBoxes = [];

  // 新增：不一致原因的输入控制器
  TextEditingController _discrepancyInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeService();
    items = widget.boxItems; // 使用传递的款箱数据
  }

  Future<void> _initializeService() async {
    _service = await Service18082.create();
  }

  // 款箱列表
  Widget cashBoxList(List<Map<String, dynamic>> items) {
    return Column(
      children: [
        // 物品总数显示
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

        // 款箱列表
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
                              item['boxCode'].toString(),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.white, // 圆形背景色
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
                  ));
            },
          ),
        ),
      ],
    );
  }

  // 根据款箱编号查找 implNo
  String? findImplNoByBoxCode(String boxCode) {
    final List<dynamic>? implBoxDetail =
        widget.point['implBoxDetail'] as List<dynamic>?;
    if (implBoxDetail != null) {
      for (var impl in implBoxDetail) {
        if (impl is Map<String, dynamic>) {
          final String implNo = impl['implNo'].toString();
          final List<dynamic>? boxDetail = impl['boxDetail'] as List<dynamic>?;
          if (boxDetail != null) {
            for (var box in boxDetail) {
              if (box is Map<String, dynamic> && box['boxNo'] == boxCode) {
                return implNo;
              }
            }
          }
        }
      }
    }
    return null;
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
                // 提交网点交接信息
                // 这里检查的是所有款箱中是否有scanStatus为1（未扫描）的
                // 如果存在，且数量大于0，则提示用户先完成扫描
                if (items
                    .where((item) =>
                        item['scanStatus'].toString() == '1') // 注意这里是 '1' 未扫描
                    .isNotEmpty) {
                  // 判断是否有未扫描的款箱
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('存在未扫描的款箱，请先完成扫描'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Color.fromARGB(255, 219, 3, 3),
                    ),
                  );
                } else {
                  _showVerificationDialog(items);
                }
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('确认交接'),
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

  // 人车核验对话框
  Future<void> _showVerificationDialog(List<Map<String, dynamic>> items) async {
    bool isConsistent = true;
    String? selectedReason; // 将 reason 更名为 selectedReason 以区分输入内容
    List<String> reasons = ['押运车信息不符', '押运员信息不符', '其他原因'];
    String? specificDiscrepancyInput; // 用于存储用户输入的具体不一致信息

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            // 使用 setStateInDialog 更新对话框内部状态
            return AlertDialog(
              title: const Text('人车核验',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                // 使用 SingleChildScrollView 防止内容溢出
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 押运车信息
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Text('押运车: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(findLineByOrgNo(
                                  widget.point['orgNo'].toString())!['carNo']
                              .toString()),
                        ],
                      ),
                    ),
                    // 押运员信息
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Text('押运员: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(findLineByOrgNo(widget.point['orgNo']
                                  .toString())!['escortName']
                              .toString()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 一致性选择
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: isConsistent,
                          onChanged: (value) {
                            setStateInDialog(() {
                              isConsistent = value!;
                              selectedReason = null; // 一致时清空原因和输入
                              _discrepancyInputController.clear();
                            });
                          },
                        ),
                        const Text('一致'),
                        const SizedBox(width: 20),
                        Radio<bool>(
                          value: false,
                          groupValue: isConsistent,
                          onChanged: (value) {
                            setStateInDialog(() {
                              isConsistent = value!;
                            });
                          },
                        ),
                        const Text('不一致'),
                      ],
                    ),
                    // 不一致原因选择及输入框
                    if (!isConsistent)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text('请选择不一致原因:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButton<String>(
                              value: selectedReason,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: reasons.map((String reason) {
                                return DropdownMenuItem<String>(
                                  value: reason,
                                  child: Text(reason),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setStateInDialog(() {
                                  selectedReason = value;
                                  // 根据选择的原因，清空并更新输入框提示
                                  _discrepancyInputController.clear();
                                });
                              },
                              hint: const Text('请选择原因'),
                            ),
                          ),
                          if (selectedReason != null) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _discrepancyInputController,
                              decoration: InputDecoration(
                                labelText:
                                    _getDiscrepancyInputLabel(selectedReason!),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    if (!isConsistent) {
                      if (selectedReason == null || selectedReason!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('请选择不一致原因'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      if (_discrepancyInputController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('请输入具体的不一致信息'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      specificDiscrepancyInput =
                          _discrepancyInputController.text.trim();
                    }
                    Navigator.pushNamed(
                        context, '/outlets/box_scan_verify_page', arguments: {
                          'lineName': findLineByOrgNo(widget.point['orgNo'].toString())!['lineName'].toString(),
                          'escortName': findLineByOrgNo(widget.point['orgNo'].toString())!['escortName'].toString(),
                          'items': items,
                        });
                  },
                  child: const Text('下一步'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 辅助方法：根据不一致原因获取输入框标签
  String _getDiscrepancyInputLabel(String reason) {
    switch (reason) {
      case '押运车信息不符':
        return '请输入实际押运车号';
      case '押运员信息不符':
        return '请输入实际押运员信息';
      case '其他原因':
        return '请输入具体原因';
      default:
        return '请输入不一致信息';
    }
  }

  // 手工匹配控件 - 改为选择未扫描款箱（多选）
  Widget manualMatch() {
    return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // 获取未扫描的款箱 (scanStatus == 1)
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

            // 每次打开弹窗时，清空之前的选择，并用当前已扫描的标签初始化已选列表
            // 这样可以避免重复选择已扫描的，同时保持之前选中的状态
            _selectedManualBoxes = []; // 每次打开弹窗时清空，确保新选择
            // 如果希望在弹窗打开时，之前已通过扫描匹配的款箱默认选中，
            // 并且手工匹配后又取消的款箱也显示为未选，可以根据_uhfScannedTags来初始化
            // 考虑到是“手工匹配未扫描款箱”，所以不应该默认选中任何项
            // 只需要确保unscannedItems是正确的未扫描列表即可。

            showDialog<void>(
              context: context,
              builder: (context) {
                // 使用 StatefulBuilder 来管理对话框内部的状态
                return StatefulBuilder(
                  builder:
                      (BuildContext context, StateSetter setStateInDialog) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '手工匹配',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_selectedManualBoxes.length}/${unscannedItems.length}',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                      content: SizedBox(
                        width: double.maxFinite,
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setStateInDialog(() {
                                      final bool allSelected =
                                          _selectedManualBoxes.length ==
                                              unscannedItems.length;
                                      if (allSelected) {
                                        _selectedManualBoxes = [];
                                      } else {
                                        _selectedManualBoxes =
                                            List<Map<String, dynamic>>.from(
                                                unscannedItems);
                                      }
                                    });
                                  },
                                  child: Text(
                                    _selectedManualBoxes.length ==
                                            unscannedItems.length
                                        ? '取消全选'
                                        : '全选',
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 1),
                            const SizedBox(height: 4),
                            Expanded(
                              child: ListView.separated(
                                itemCount: unscannedItems.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final box = unscannedItems[index];
                                  final bool isSelected =
                                      _selectedManualBoxes.any(
                                    (selectedBox) =>
                                        selectedBox['boxCode'] ==
                                        box['boxCode'],
                                  );
                                  return CheckboxListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(box['boxCode'].toString()),
                                    value: isSelected,
                                    onChanged: (bool? newValue) {
                                      setStateInDialog(() {
                                        if (newValue == true) {
                                          if (!_selectedManualBoxes.any(
                                              (selected) =>
                                                  selected['boxCode'] ==
                                                  box['boxCode'])) {
                                            _selectedManualBoxes.add(box);
                                          }
                                        } else {
                                          _selectedManualBoxes.removeWhere(
                                            (selectedBox) =>
                                                selectedBox['boxCode'] ==
                                                box['boxCode'],
                                          );
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  _selectedManualBoxes = [];
                                });
                              },
                              child: const Text('取消'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF29A8FF),
                                side:
                                    const BorderSide(color: Color(0xFF29A8FF)),
                                minimumSize: const Size(88, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (_selectedManualBoxes.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('请选择至少一个款箱进行匹配'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                final List<Map<String, dynamic>>
                                    selectedSnapshot =
                                    List<Map<String, dynamic>>.from(
                                        _selectedManualBoxes);
                                final int selectedCount =
                                    selectedSnapshot.length;
                                for (var box in selectedSnapshot) {
                                  _handleUHFTagScanned(
                                      box['boxCode'].toString());
                                }
                                Navigator.pop(context);
                                setState(() {
                                  _selectedManualBoxes = [];
                                });
                              },
                              child: const Text('确认匹配'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFF29A8FF),
                                minimumSize: const Size(96, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
        ));
  }

  // 更新款箱状态
  Future<void> _updateCashBoxStatus(String boxCode, int scanStatus) async {
    try {
      // 找到对应的款箱并更新状态
      setState(() {
        for (var item in items) {
          if (item['boxCode'] == boxCode) {
            item['scanStatus'] = scanStatus;
            break;
          }
        }
        // 如果是扫描成功（scanStatus == 0），则添加到已扫描标签列表
        if (scanStatus == 0 && !_uhfScannedTags.contains(boxCode)) {
          _uhfScannedTags.insert(0, boxCode);
          if (_uhfScannedTags.length > 100) {
            _uhfScannedTags.removeLast();
          }
          _scannedBoxes.add({"boxNo": boxCode});
        } else if (scanStatus == 1) {
          // 如果是取消匹配（scanStatus == 1），则从已扫描标签列表移除
          _uhfScannedTags.remove(boxCode);
          _scannedBoxes.removeWhere((box) => box['boxNo'] == boxCode);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新款箱状态失败: $e')),
        );
      }
    }
  }

  // UHF扫描和手工匹配的统一处理函数
  void _handleUHFTagScanned(String tag) {
    // 确保tag长度不会过长，根据实际UHF标签长度调整
    if (tag.length > 8) {
      // 假设款箱编码最大8位
      tag = tag.substring(0, 8);
    }

    // 检查这个tag是否在当前待处理的items列表中
    final matchedItem = items.firstWhere(
        (item) => item['boxCode'].toString() == tag,
        orElse: () => <String, dynamic>{}); // 如果没找到，返回空Map

    if (matchedItem.isNotEmpty) {
      if (matchedItem['scanStatus'] == 0) {
        // 已经扫描过
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('款箱已扫描'),
            content: Text('款箱 $tag 已扫描'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      } else {
        // 未扫描，进行更新
        _updateCashBoxStatus(tag, 0); // 将状态更新为已扫描
      }
    } else {
      // tag不在当前款箱列表中
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('款箱不在列表'),
          content: Text('款箱 $tag 不在当前线路的款箱列表中'),
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
    // 这里不再需要从 _uhfScannedTags 移除，因为 _updateCashBoxStatus 会处理
    _updateCashBoxStatus(item['boxCode'].toString(), 1); // 状态改回未扫描
    // _scannedBoxes 的移除也放在 _updateCashBoxStatus 中
  }

  void _handleUHFError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('UHF错误: $error')),
      );
    }
  }

  // 根据 orgNo 查找线路对象
  Map<String, dynamic>? findLineByOrgNo(String orgNo) {
    for (final line in widget.lines) {
      final List<dynamic>? planDTOS = line['planDTOS'] as List<dynamic>?;
      if (planDTOS != null) {
        for (final plan in planDTOS) {
          if (plan is Map<String, dynamic>) {
            final List<dynamic>? deliverOrgNos =
                plan['deliverOrgNo'] as List<dynamic>?;
            if (deliverOrgNos != null) {
              for (final org in deliverOrgNos) {
                if (org is Map<String, dynamic> && org['orgNo'] == orgNo) {
                  return line;
                }
              }
            }

            final List<dynamic>? receiveOrgNos =
                plan['receiveOrgNo'] as List<dynamic>?;
            if (receiveOrgNos != null) {
              for (final org in receiveOrgNos) {
                if (org is Map<String, dynamic> && org['orgNo'] == orgNo) {
                  return line;
                }
              }
            }
          }
        }
      }
    }
    return null;
  }

  // 自定义内容体的头部 - 添加线路、车、押运员信息
  Widget customBodyHeader(List<Map<String, dynamic>> items) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                    "${findLineByOrgNo(widget.point['orgNo'].toString())!['lineName'].toString()}",
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
                                    "${findLineByOrgNo(widget.point['orgNo'].toString())!['carNo'].toString()}",
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
                                    "${findLineByOrgNo(widget.point['orgNo'].toString())!['escortName'].toString()}",
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
                    // 下方白色内容区
                    Container(
                      margin: const EdgeInsets.only(left: 16, right: 16),
                      // padding: const EdgeInsets.symmetric(
                      //     horizontal: 10, vertical: 24),
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
                          Expanded(child: manualMatch()),
                          // 右侧按钮
                          Expanded(
                              child: Material(
                                  color: Colors.transparent,
                                  child: UHFScanButton(
                                    buttonWidth: double.infinity,
                                    buttonHeight: 28,
                                    onTagScanned: _handleUHFTagScanned,
                                    onError: _handleUHFError,
                                  ))),
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
      title: widget.point['orgName'].toString(),
      showBackButton: true,
      onBackPressed: () {
        Navigator.pop(context);
      },
      child: Column(
        children: [
          customBodyHeader(items),
          Expanded(
            child: cashBoxList(items),
          ),
          footerButton(items), // 底部按钮
        ],
      ),
    );
  }

  @override
  void dispose() {
    _discrepancyInputController.dispose();
    // 在页面销毁时停止UHF扫描
    if (_isUHFScanning) {
      _isUHFScanning = false;
    }
    super.dispose();
  }
}
