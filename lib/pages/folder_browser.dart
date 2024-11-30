import 'package:flutter/material.dart';
import '../model/file_manager.dart';
import '../utils/logger.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'text_reader.dart';
import '../model/settings.dart';

class FolderBrowser extends StatefulWidget {
  const FolderBrowser({super.key});

  @override
  State<FolderBrowser> createState() => _FolderBrowserState();
}

class _FolderBrowserState extends State<FolderBrowser> {
  List<FileInfo> _files = [];
  final ScrollController _scrollController = ScrollController();

  String get _currentPath => Settings.instance.currentPath;
  
  String _getTitle() {
    return FileManager.instance.isRootPath(_currentPath) ? 'AEditor' : path.basename(_currentPath);
  }

  @override
  void initState() {
    super.initState();
    _initializeFolder();
  }

  Future<void> _initializeFolder() async {
    String? lastReadingFile = Settings.instance.currentReadingTextFile;
    if (lastReadingFile != null) {
      String lastReadingDir = path.dirname(lastReadingFile);
      Logger.instance.d('Last reading directory: $lastReadingDir');
      
      await Settings.instance.setCurrentPath(lastReadingDir);
      await _loadFiles();
      
      // 等待文件列表加载完成后再滚动
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFile(lastReadingFile);
      });
    } else {
      _loadFiles();
    }
  }

  void _scrollToFile(String filePath) {
    String fileName = path.basename(filePath);
    int fileIndex = _files.indexWhere((file) => file.name == fileName);
    
    if (fileIndex != -1) {
      Logger.instance.d('Scrolling to file: $fileName at index $fileIndex');
      double offset = fileIndex * 56.0; // 假设每个ListTile高度为56
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  void _handleFolderTap(FileInfo folder) async {
    await Settings.instance.setCurrentPath(folder.path);
    _loadFiles();
  }

  Future<bool> _onWillPop() async {
    Logger.instance.d('Handling back press, current path: $_currentPath');
    
    if (FileManager.instance.isRootPath(_currentPath)) {
      Logger.instance.i('At root directory, allowing page exit');
      return true;
    }
    
    String parentPath = path.dirname(_currentPath);
    Logger.instance.d('Moving to parent directory: $parentPath');
    
    await Settings.instance.setCurrentPath(parentPath);
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
          controller: _scrollController,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TextReader(filePath: file.path),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
} 