import 'package:flutter/material.dart';

class RoleManagementPage extends StatelessWidget {
  const RoleManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('角色管理'),
      ),
      body: const Center(
        child: Text('角色管理页面'),
      ),
    );
  }
}