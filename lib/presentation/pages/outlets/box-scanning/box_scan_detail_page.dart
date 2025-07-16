import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/uhf_scan_button.dart';
import 'package:tj_tms_mobile/data/datasources/api/18082/service_18082.dart';
import 'package:tj_tms_mobile/presentation/pages/outlets/box-scanning/box_scan_verify_page.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/blue_polygon_background.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/blank_item_card.dart';

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
  late final Service18082 _service;
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
  // 新增：用于存储复合验证的账号和密码
  TextEditingController _compoundAccountController = TextEditingController();
  TextEditingController _compoundPasswordController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _service = Service18082();
    print("widget:${widget.point}");
    print("widget.boxItems: ${widget.boxItems}");
    items = widget.boxItems; // 使用传递的款箱数据
  }

  // 自定义appBar - 简化标题
  PreferredSizeWidget appCustomBar(BuildContext context) {
    String orgName = widget.point != null && widget.point['orgName'] != null
        ? widget.point['orgName'].toString()
        : '未知网点';
    return AppBar(
      title: Text(orgName),
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
                    padding:
                    const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
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
    final List<dynamic>? implBoxDetail = widget.point['implBoxDetail'] as List<dynamic>?;
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
                    .where((item) => item['scanStatus'].toString() == '1') // 注意这里是 '1' 未扫描
                    .isNotEmpty) { // 判断是否有未扫描的款箱
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
                padding: const EdgeInsets.symmetric(vertical: 12),
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
    List<String> reasons = [
      '押运车信息不符',
      '押运员信息不符',
      '其他原因'
    ];
    String? specificDiscrepancyInput; // 用于存储用户输入的具体不一致信息

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) { // 使用 setStateInDialog 更新对话框内部状态
            return AlertDialog(
              title: const Text('人车核验',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView( // 使用 SingleChildScrollView 防止内容溢出
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
                          Text(findLineByOrgNo(widget.point['orgNo'].toString())!['carNo'].toString()),
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
                          Text(findLineByOrgNo(widget.point['orgNo'].toString())!['escortName'].toString()),
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
                                labelText: _getDiscrepancyInputLabel(selectedReason!),
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
                      specificDiscrepancyInput = _discrepancyInputController.text.trim();
                    }

                    Navigator.pop(context); // 关闭人车核验对话框
                    // 调用复合验证对话框
                    await _showCompoundVerificationDialog(
                      items,
                      isConsistent,
                      selectedReason,
                      specificDiscrepancyInput,
                    );
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

  // 复合验证对话框
  Future<void> _showCompoundVerificationDialog(
      List<Map<String, dynamic>> items,
      bool isConsistent,
      String? verificationReason, // 人车核验不一致的原因
      String? specificDiscrepancyInput, // 人车核验不一致的具体输入
      ) async {
    _compoundAccountController.clear(); // 清空上次输入
    _compoundPasswordController.clear(); // 清空上次输入

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('复合验证',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _compoundAccountController,
                decoration: const InputDecoration(
                  labelText: '账户',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _compoundPasswordController,
                obscureText: true, // 密码隐藏
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                ),
              ),
              // 您也可以在这里添加人脸识别的按钮或其他UI
              // const SizedBox(height: 16),
              // ElevatedButton(
              //   onPressed: () {
              //     // TODO: 实现人脸识别逻辑
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text('调用人脸识别...')),
              //     );
              //   },
              //   child: const Text('人脸识别'),
              // ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final String account = _compoundAccountController.text.trim();
                final String password = _compoundPasswordController.text.trim();

                if (account.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入账户和密码'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                // 调用复合接口 /aaaaaaa
                try {
                  // 模拟网络请求
                  // final response = await _service.post('/aaaaaaa', body: {
                  //   'account': account,
                  //   'password': password,
                  //   // 可以根据需要添加其他参数，例如人车核验结果
                  //   'isConsistent': isConsistent,
                  //   'verificationReason': verificationReason,
                  //   'specificDiscrepancyInput': specificDiscrepancyInput,
                  // });


                  // 假设后端返回 success: true 表示验证成功
                  if (/*response['success'] == */true) {
                    Navigator.pop(context); // 关闭复合验证对话框
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('复合验证成功！'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    // 复合验证成功后，调用最终交接接口
                    _submitHandoverToBackend(items, isConsistent, verificationReason, specificDiscrepancyInput);

                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('复合验证失败: ${/*response['message'] ?? */'未知错误'}'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('复合验证请求失败: $e'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }
  // 定义 _submitHandoverToBackend 方法 (原 _submitHandover)
// 复合验证成功后，需要把当前交接的所有impl一起发给后端的交接接口
  void _submitHandoverToBackend(
      List<Map<String, dynamic>> items,
      bool isConsistent,
      String? verificationReason,
      String? specificDiscrepancyInput,
      ) async {
    print('最终提交交接信息...');
    print('所有款箱数据: $items');
    print('人车一致: $isConsistent');
    if (!isConsistent) {
      print('不一致原因: $verificationReason');
      print('具体不一致输入: $specificDiscrepancyInput');
    }

    // 提取所有 impl 信息
    List<Map<String, dynamic>> allImplDetails = [];
    if (widget.point['implBoxDetail'] != null) {
      // allImplDetails.addAll(List<Map<String, dynamic>>.from(widget.point['implBoxDetail']));
    }

    // 构建最终提交给后端的数据结构
    Map<String, dynamic> submissionData = <String, dynamic>{
      'orgNo': widget.point['orgNo'], // 当前交接网点编号
      'handoverItems': items, // 所有款箱的当前状态
      'allImplDetails': allImplDetails, // 所有 impl 信息
      'verificationResult': { // 人车核验结果
        'isConsistent': isConsistent,
        'reason': verificationReason,
        'specificInput': specificDiscrepancyInput,
      },
      // 可以在这里添加其他需要提交的交接信息，如时间、操作员等
    };

    try {
      // 假设您的最终交接接口是 /handover/submit
      // final response = await _service.post('/handover/submit', body: submissionData);

      if (/*response['success'] == */true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('交接信息成功提交到后端！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        // 提交成功后，可以导航回首页或者显示交接成功页面
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home', // 假设您的首页路由是 '/home'
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('交接信息提交失败: ${/*response['message'] ??*/ '未知错误'}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('交接信息提交请求失败: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
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
            List<Map<String, dynamic>> unscannedItems = items
                .where((item) => item['scanStatus'] == 1)
                .toList();

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
                  builder: (BuildContext context, StateSetter setStateInDialog) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: const Text('手工匹配（多选）',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      content: SizedBox(
                        width: double.maxFinite,
                        // 设置一个最大高度，以防款箱过多导致溢出
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: ListView.builder(
                          itemCount: unscannedItems.length,
                          itemBuilder: (context, index) {
                            final box = unscannedItems[index];
                            // 判断当前款箱是否在 _selectedManualBoxes 中
                            final bool isSelected = _selectedManualBoxes.any((selectedBox) => selectedBox['boxCode'] == box['boxCode']);

                            return CheckboxListTile(
                              title: Text(box['boxCode'].toString()),
                              value: isSelected,
                              onChanged: (bool? newValue) {
                                setStateInDialog(() { // 使用 setStateInDialog 更新弹窗内部状态
                                  if (newValue == true) {
                                    // 检查是否已经存在，避免重复添加
                                    if (!_selectedManualBoxes.any((selected) => selected['boxCode'] == box['boxCode'])) {
                                      _selectedManualBoxes.add(box);
                                    }
                                  } else {
                                    _selectedManualBoxes.removeWhere((selectedBox) => selectedBox['boxCode'] == box['boxCode']);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      actionsPadding: const EdgeInsets.only(bottom: 8),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                // 取消时清空已选列表，确保下次打开是干净的
                                setState(() { // 更新主页面状态
                                  _selectedManualBoxes = [];
                                });
                              },
                              child: const Text('取消'),
                              style: TextButton.styleFrom(
                                foregroundColor: Color(0xFF29A8FF),
                                side: const BorderSide(color: Color(0xFF29A8FF)),
                                minimumSize: const Size(80, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            TextButton(
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

                                // 遍历已选款箱并处理
                                for (var box in _selectedManualBoxes) {
                                  _handleUHFTagScanned(box['boxCode'].toString());
                                }
                                Navigator.pop(context);
                                setState(() { // 更新主页面状态，清空已选列表
                                  _selectedManualBoxes = [];
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('已成功匹配 ${_selectedManualBoxes.length} 个款箱！'),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: const Text('确认匹配'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFF29A8FF),
                                minimumSize: const Size(80, 36),
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
        )
    );
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
        } else if (scanStatus == 1) { // 如果是取消匹配（scanStatus == 1），则从已扫描标签列表移除
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
    if (tag.length > 8) { // 假设款箱编码最大8位
      tag = tag.substring(0, 8);
    }

    // 检查这个tag是否在当前待处理的items列表中
    final matchedItem = items.firstWhere(
            (item) => item['boxCode'].toString() == tag,
        orElse: () => <String, dynamic>{}); // 如果没找到，返回空Map

    if (matchedItem.isNotEmpty) {
      if (matchedItem['scanStatus'] == 0) { // 已经扫描过
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
      } else { // 未扫描，进行更新
        _updateCashBoxStatus(tag, 0); // 将状态更新为已扫描
      }
    } else { // tag不在当前款箱列表中
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
            final List<dynamic>? deliverOrgNos = plan['deliverOrgNo'] as List<dynamic>?;
            if (deliverOrgNos != null) {
              for (final org in deliverOrgNos) {
                if (org is Map<String, dynamic> && org['orgNo'] == orgNo) {
                  return line;
                }
              }
            }

            final List<dynamic>? receiveOrgNos = plan['receiveOrgNo'] as List<dynamic>?;
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
      padding: const EdgeInsets.all(8),
      color: Colors.transparent,
      child: BluePolygonBackground(
        width: 900,
        height: 130,
        child: Column(
          children: [
            // 顶部信息区，占整体宽度的 1/3
            Container(
              height: 132/3, // 假设 BluePolygonBackground 宽度为 900
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 线路信息
                  Text(
                    findLineByOrgNo(widget.point['orgNo'].toString())!['lineName'].toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  // 车信息
                  Text(
                    findLineByOrgNo(widget.point['orgNo'].toString())!['carNo'].toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  // 押运员信息
                  Text(
                    findLineByOrgNo(widget.point['orgNo'].toString())!['escortName'].toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // 下方白色内容区，占整体高度的 2/3
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.only(left: 16, right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 24,
                ),
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
                    // 左侧按钮
                    Expanded(
                      child: manualMatch(),
                    ),
                    // 右侧按钮
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: UHFScanButton(
                          buttonWidth: double.infinity,
                          buttonHeight: 48,
                          onTagScanned: _handleUHFTagScanned,
                          onError: _handleUHFError,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
          title: Text(
            widget.point['orgName'].toString(),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF29A8FF),
          foregroundColor: Colors.black12,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {}, // 不再需要重试
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
            customBodyHeader(items),
            Expanded(
              child: cashBoxList(items),
            ),
            footerButton(items), // 底部按钮
          ],
        ));
  }

  @override
  void dispose() {
    _discrepancyInputController.dispose();
    _compoundAccountController.dispose();
    _compoundPasswordController.dispose();
    // 在页面销毁时停止UHF扫描
    if (_isUHFScanning) {
      // 假设 UHFScanButton 内部会处理 dispose 时的停止逻辑
      // 如果有外部控制 UHF 设备的方法，需要在这里调用
      // 例如：_uhfPlugin.stopScan();
      _isUHFScanning = false;
    }
    super.dispose();
  }
}