import 'package:flutter/material.dart';

class StoreDashboard extends StatelessWidget {
  const StoreDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المتجر'),
        backgroundColor: const Color(0xFF54d4dd),
      ),
      body: const Center(
        child: Text(
          'مرحباً موظف المتجر',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}