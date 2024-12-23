import 'package:flutter/material.dart';
import '../models/file_manager.dart';
import '../utils/logger.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'text_reader.dart';
import '../models/settings.dart';
import 'epub_reader.dart';

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
    return FileManager.instance.isRootPath(_currentPath)
        ? 'AEditor'
        : path.basename(_currentPath);
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

        // 对文件夹进行排序，文件夹排在前
        _files.sort((a, b) {
          // 文件夹排在前
          if (!a.isFile && b.isFile) return -1; // a 是文件夹，b 是文件
          if (a.isFile && !b.isFile) return 1; // a 是文件，b 是文件夹

          // 获取比较结果
          var resultA = _chineseToNumber(a.name);
          var resultB = _chineseToNumber(b.name);

          // 打印结果
          Logger.instance.d(
              'File: "${a.name}" -> Prefix: "${resultA['prefix']}", Number: "${resultA['number']}"');
          Logger.instance.d(
              'File: "${b.name}" -> Prefix: "${resultB['prefix']}", Number: "${resultB['number']}"');

          String prefixA = resultA['prefix']!;
          String numberA = resultA['number']!;
          String prefixB = resultB['prefix']!;
          String numberB = resultB['number']!;

          // 首先比较prefix
          int prefixComparison = prefixA.compareTo(prefixB);
          if (prefixComparison != 0) {
            return prefixComparison; // 如果prefix不同，直接返回比较结果
          }

          // 如果prefix相同，比较数字
          return int.parse(numberA).compareTo(int.parse(numberB));
        });
      });
    } catch (e) {
      Logger.instance.e('Error loading files', e);
    }
  }

  // 汉字数字转换为阿拉伯数字
  Map<String, String> _chineseToNumber(String str) {
    const Map<String, int> chineseNumbers = {
      '零': 0,
      '一': 1,
      '二': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
      '十': 10,
      '百': 100,
      '千': 1000,
      '万': 10000,
      '亿': 100000000,
    };

    int result = 0;
    int temp = 0;
    bool hasNumber = false; // 用于标记是否遇到数字
    String prefix = ''; // 用于保存数字前面的部分

    for (int i = 0; i < str.length; i++) {
      String char = str[i];
      if (chineseNumbers.containsKey(char)) {
        int value = chineseNumbers[char]!;

        if (value == 10 || value == 100 || value == 1000) {
          if (temp == 0) {
            temp = 1; // 处理如“十”开头的情况
          }
          temp *= value;
          result += temp;
          temp = 0;
        } else {
          temp = value;
        }
        hasNumber = true; // 标记已经遇到数字
      } else {
        // 如果遇到非数字字符
        if (!hasNumber) {
          prefix += char; // 保留数字前面的部分
        } else {
          if (temp > 0) {
            result += temp;
          }
          // 如果前面已经遇到数字，返回结果
          return {'prefix': prefix, 'number': result.toString()}; // 返回prefix和数字
        }
      }
    }

    return {'prefix': prefix, 'number': result.toString()}; // 返回最终结果
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
      await FileManager.instance
          .createFileOrFolder(newPath, isFolder); // 使用 FileManager 创建文件或文件夹
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
                        file.isFile
                            ? Icons.insert_drive_file
                            : Icons.folder_outlined,
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
                          // 检查文件后缀
                          if (file.name.endsWith('.epub')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EpubReader(epubPath: file.path),
                              ),
                            );
                          } else {
                            setState(() {
                              _showMask = true;
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TextReader(filePath: file.path),
                              ),
                            ).then((_) {
                              Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                if (mounted) {
                                  setState(() {
                                    _showMask = false;
                                  });
                                }
                              });
                            });
                          }
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
