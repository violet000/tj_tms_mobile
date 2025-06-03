import 'package:flutter/material.dart';

class BoxHandoverPage extends StatefulWidget {
  const BoxHandoverPage({super.key});

  @override
  State<BoxHandoverPage> createState() => _BoxHandoverPageState();
}

class _BoxHandoverPageState extends State<BoxHandoverPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('款箱交接'),
        backgroundColor: const Color(0xFF0489FE),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color.fromARGB(255, 243, 240, 240),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF0489FE)),
                  const SizedBox(width: 8),
                  const Text(
                    '待交接款箱',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // TODO: 实现刷新功能
                    },
                    child: const Text('刷新'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 0, // TODO: 添加实际数据
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: const Text('款箱编号'),
                      subtitle: const Text('状态：待交接'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          // TODO: 实现交接功能
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0489FE),
                        ),
                        child: const Text('交接'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 