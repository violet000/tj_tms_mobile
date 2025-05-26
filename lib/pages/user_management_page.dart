import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tj_tms_mobile/widgets/uhf_scan_button.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final List<String> _scannedTags = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UHF Reader'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            child: UHFScanButton(
              buttonWidth: 100,
              buttonHeight: 48,
              onTagScanned: (String tag) {
                Future.microtask(() {
                  if (mounted) {
                    setState(() {
                      if (!_scannedTags.contains(tag)) {
                        _scannedTags.insert(0, tag);
                        if (_scannedTags.length > 100) {
                          _scannedTags.removeLast();
                        }
                      }
                    });
                  }
                });
              },
              onError: (String error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('错误: $error')),
                  );
                }
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _scannedTags.isEmpty
                ? const Center(
                    child: Text('暂无扫描数据'),
                  )
                : ListView.builder(
                    itemCount: _scannedTags.length,
                    itemBuilder: (context, index) {
                      final tag = _scannedTags[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text('EPC: $tag'),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () => _copyToClipboard(tag),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板')),
      );
    }
  }
}