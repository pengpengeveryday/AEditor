import 'package:flutter/material.dart';
import '../model/file_manager.dart';
import '../utils/logger.dart';

class FolderBrowser extends StatefulWidget {
  final String initialPath;

  const FolderBrowser({
    super.key,
    required this.initialPath,
  });

  @override
  State<FolderBrowser> createState() => _FolderBrowserState();
}

class _FolderBrowserState extends State<FolderBrowser> {
  List<FileInfo> _files = [];
  late String _currentPath;

  String _getTitle() {
    return _currentPath == '/sdcard' ? 'AEditor' : _currentPath.split('/').last;
  }

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final files = await FileManager.instance.loadFiles(_currentPath);
      setState(() {
        _files = files;
      });
    } catch (e) {
      Logger.instance.e('Error loading files', e);
    }
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FolderBrowser(
                      initialPath: file.path,
                    ),
                  ),
                );
              } else {
                // TODO: 处理文件点击事件
              }
            },
          );
        },
      ),
    );
  }
} 