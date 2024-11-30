import 'package:flutter/material.dart';
import '../model/file_manager.dart';
import '../utils/logger.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

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
    return FileManager.instance.isRootPath(_currentPath) ? 'AEditor' : path.basename(_currentPath);
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

  void _handleFolderTap(FileInfo folder) {
    setState(() {
      _currentPath = folder.path;
    });
    _loadFiles();
  }

  String currentPath = FileManager.rootPath;  // 使用 FileManager 中定义的根路径

  Future<bool> _onWillPop() async {
    Logger.instance.d('Handling back press, current path: $_currentPath');
    
    if (FileManager.instance.isRootPath(_currentPath)) {
      Logger.instance.i('At root directory, allowing page exit');
      return true;
    }
    
    String parentPath = path.dirname(_currentPath);
    Logger.instance.d('Moving to parent directory: $parentPath');
    
    setState(() {
      _currentPath = parentPath;
    });
    await _loadFiles();
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                  _handleFolderTap(file);
                } else {
                  // TODO: 处理文件点击事件
                }
              },
            );
          },
        ),
      ),
    );
  }
} 