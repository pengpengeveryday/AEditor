import 'package:flutter/material.dart';
import '../model/file_manager.dart';
import '../utils/logger.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<FileInfo> _files = [];
  String _currentPath = '/sdcard';

  String _getTitle() {
    return _currentPath == '/sdcard' ? 'AEditor' : _currentPath.split('/').last;
  }

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final files = await FileManager.instance.loadFiles('/sdcard');
    setState(() {
      _files = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _getTitle(),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // TODO: 实现菜单功能
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            leading: Icon(
              file.isFile ? Icons.insert_drive_file : Icons.folder_outlined,
              color: Colors.white,
              size: 20,
            ),
            title: Text(
              file.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            onTap: () {
              if (!file.isFile) {
                // TODO: 处理文件夹点击事件，进入下一级目录
              } else {
                // TODO: 处理文件点击事件
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          // TODO: 实现添加功能
        },
      ),
    );
  }
} 