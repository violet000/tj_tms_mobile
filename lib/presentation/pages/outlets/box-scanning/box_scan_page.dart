import 'package:flutter/material.dart';

class BoxScanPage extends StatefulWidget {
  const BoxScanPage({super.key});

  @override
  State<BoxScanPage> createState() => _BoxScanPageState();
}

class _BoxScanPageState extends State<BoxScanPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('款箱扫描'),
        backgroundColor: const Color(0xFF29A8FF),
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color.fromARGB(255, 243, 240, 240),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 100,
                color: Color(0xFF29A8FF),
              ),
              const SizedBox(height: 20),
              const Text(
                '请扫描款箱二维码',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // TODO: 实现扫描功能
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF29A8FF),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '开始扫描',
                  style: TextStyle(
                    fontSize: 16,
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
} 