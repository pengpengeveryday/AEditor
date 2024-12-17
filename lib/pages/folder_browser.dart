import 'package:flutter/material.dart';
import '../models/file_manager.dart';
import '../utils/logger.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'text_reader.dart';
import '../models/settings.dart';

class FolderBrowser extends StatefulWidget {
  const FolderBrowser({super.key});

  @override
  State<FolderBrowser> createState() => _FolderBrowserState();
}

class _FolderBrowserState extends State<FolderBrowser> {
  List<FileInfo> _files = [];
  final ScrollController _scrollController = ScrollController();
  bool _showMask = false;
  bool _isScrolling = false;

  String get _currentPath => Settings.instance.currentPath;
  
  String _getTitle() {
    return FileManager.instance.isRootPath(_currentPath) ? 'AEditor' : path.basename(_currentPath);
  }

  @override
  void initState() {
    super.initState();
    _initializeFolder();
    _scrollController.addListener(() {
      if (_scrollController.position.isScrollingNotifier.value) {
        _isScrolling = true;
      } else {
        _isScrolling = false;
      }
    });
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

  void _showCreateFileDialog() {
    String fileName = '';
    bool isFolder = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('创建文件或文件夹'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: '文件名'),
                    onChanged: (value) {
                      fileName = value;
                    },
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: isFolder,
                        onChanged: (value) {
                          setState(() {
                            isFolder = value ?? false;
                          });
                        },
                      ),
                      const Text('创建为文件夹'),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (fileName.isNotEmpty) {
                  _createFileOrFolder(fileName, isFolder);
                }
              },
              child: const Text('创建'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createFileOrFolder(String name, bool isFolder) async {
    try {
      String newPath = path.join(_currentPath, name);
      await FileManager.instance.createFileOrFolder(newPath, isFolder); // 使用 FileManager 创建文件或文件夹
      await _loadFiles(); // 重新加载文件列表
    } catch (e) {
      Logger.instance.e('Error creating file or folder', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          Scaffold(
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
              itemCount: _files.length + 1, // 增加 +1 以显示创建项
              itemBuilder: (context, index) {
                if (index == _files.length) {
                  // 显示创建文件/文件夹的项
                  return ListTile(
                    leading: const Icon(Icons.add, color: Colors.white),
                    title: const Text(
                      '创建文件/文件夹',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: _showCreateFileDialog,
                  );
                }

                final file = _files[index];
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      leading: Icon(
                        file.isFile ? Icons.insert_drive_file : Icons.folder_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      title: Text(
                        file.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          height: 1.2,
                        ),
                      ),
                      onTap: () {
                        if (!file.isFile) {
                          _handleFolderTap(file);
                        } else {
                          setState(() {
                            _showMask = true;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TextReader(filePath: file.path),
                            ),
                          ).then((_) {
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted) {
                                setState(() {
                                  _showMask = false;
                                });
                              }
                            });
                          });
                        }
                      },
                    ),
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Colors.grey,
                      indent: 16.0,
                      endIndent: 16.0,
                    ),
                  ],
                );
              },
            ),
          ),
          if (_showMask)
            Positioned.fill(
              child: Container(
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }
} 