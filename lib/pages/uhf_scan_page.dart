import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/uhf_plugin_widget.dart';

class UHFScanPage extends StatefulWidget {
  const UHFScanPage({super.key});

  @override
  State<UHFScanPage> createState() => _UHFScanPageState();
}

class _UHFScanPageState extends State<UHFScanPage> {
  final List<Map<String, dynamic>> _tags = [];
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UHF标签扫描'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleScan,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _tags.length,
              itemBuilder: (context, index) {
                final tag = _tags[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text('EPC: ${tag['epc']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RSSI: ${tag['rssi']} dBm'),
                        if (tag['tid'] != null && tag['tid'].isNotEmpty)
                          Text('TID: ${tag['tid']}'),
                        if (tag['user'] != null && tag['user'].isNotEmpty)
                          Text('User: ${tag['user']}'),
                        Text('时间: ${_formatTimestamp(tag['timestamp'])}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(tag['epc']),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('已扫描到 ${_tags.length} 个标签'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour}:${date.minute}:${date.second}.${date.millisecond}';
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板')),
      );
    }
  }

  void _toggleScan() {
    setState(() {
      _isScanning = !_isScanning;
    });
  }

  @override
  void initState() {
    super.initState();
    _setupUHFPlugin();
  }

  void _setupUHFPlugin() {
    UHFPluginWidget(
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('错误: $error')),
          );
        }
      },
      onInitialized: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('UHF设备初始化成功')),
          );
        }
      },
      onDisposed: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('UHF设备已释放')),
          );
        }
      },
      builder: (context, controller) {
        return StreamBuilder<Map<String, dynamic>>(
          stream: controller.tagStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final tag = snapshot.data!;
              setState(() {
                _tags.insert(0, tag);
                if (_tags.length > 100) {
                  _tags.removeLast();
                }
              });
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
} 