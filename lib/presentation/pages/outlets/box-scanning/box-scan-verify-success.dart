import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tj_tms_mobile/presentation/state/providers/teller_verify_provider.dart';
import 'package:tj_tms_mobile/presentation/state/providers/line_info_provider.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/logger.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/page_scaffold.dart';

class BoxScanVerifySuccessPage extends StatefulWidget {
  const BoxScanVerifySuccessPage({super.key});

  @override
  State<BoxScanVerifySuccessPage> createState() =>
      _BoxScanVerifySuccessPageState();
}

class _BoxScanVerifySuccessPageState extends State<BoxScanVerifySuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String? _authenticatedVehiclePlateNumber;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lineInfoProvider = context.watch<LineInfoProvider>();
    final tellerVerifyProvider = context.watch<TellerVerifyProvider>();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args.containsKey('vehiclePlateNumber')) {
      _authenticatedVehiclePlateNumber = args['vehiclePlateNumber']?.toString();
    }
    return PageScaffold(
      title: '交接详情',
      showBackButton: false, // 不显示返回按钮，防止用户返回
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 成功图标区域（带动画）
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 4, 122, 8)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 55,
                        color: Color.fromARGB(255, 7, 108, 10),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // 成功标题（带动画）
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: const Text(
                      '交接成功！',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 交接信息卡片（带动画）
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE9ECEF),
                          width: 1,
                        ),
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
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '交接信息',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoRow('交接状态', '已完成'),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            '押运车',
                            _authenticatedVehiclePlateNumber?.toString() ?? '暂无数据',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            '复核柜员',
                            [
                              tellerVerifyProvider.getUsername(0) ?? '',
                              tellerVerifyProvider.getUsername(1) ?? '',
                            ].where((name) => name.isNotEmpty).join(', '),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            '款箱数量',
                            lineInfoProvider.itemsCountString,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            '交接网点',
                            lineInfoProvider.getOrgName,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              // 操作按钮（带动画）
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        // 返回首页按钮
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // 清除柜员人员信息
                              final tellerProvider = Provider.of<TellerVerifyProvider>(context, listen: false);
                              tellerProvider.clearAllData();
                              
                              // 返回首页
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/home',
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 7, 91, 193),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '返回首页',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 继续交接按钮
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              // 清除柜员人员信息
                              final tellerProvider = Provider.of<TellerVerifyProvider>(context, listen: false);
                              tellerProvider.clearAllData();
                              
                              // 继续下一个交接
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/outlets/box-scan',
                                (route) => false,
                                arguments: <String, dynamic>{'mode': 0},
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  const Color.fromARGB(255, 213, 81, 10),
                              side: const BorderSide(
                                  color: Color.fromARGB(255, 213, 81, 10)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              '继续交接',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // 获取当前时间
  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }
}
