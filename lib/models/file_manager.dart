import 'dart:io' as io;
import 'package:path/path.dart' as path;
import '../utils/logger.dart';

import 'package:permission_handler/permission_handler.dart';

// 在访问文件之前调用这个方法
Future<bool> requestStoragePermission() async {
  // 请求管理所有文件的权限
  var status = await Permission.manageExternalStorage.status;
  if (!status.isGranted) {
    status = await Permission.manageExternalStorage.request();
  }
  return status.isGranted;
}

class FileInfo {
  final String name;        // 文件名
  final String path;        // 完整路径
  final bool isFile;        // 是否为文件
  final String? extension;  // 文件后缀（如果是文件的话）

  FileInfo({
    required this.name,
    required this.path,
    required this.isFile,
    this.extension,
  });

  @override
  String toString() {
    final logger = Logger.instance;
    logger.d('FileInfo{name: $name, path: $path, isFile: $isFile, extension: $extension}');
    return 'FileInfo{name: $name, path: $path, isFile: $isFile, extension: $extension}';
  }
}

class FileManager {
  static final FileManager _instance = FileManager._();
  static FileManager get instance => _instance;
  
  // 添加根目录路径常量
  static const String rootPath = '/sdcard';
  
  // 私有构造函数
  FileManager._();

  /// 判断给定路径是否为根目录
  bool isRootPath(String path) {
    Logger.instance.d('Checking if path is root: $path');
    return path == rootPath;
  }

  Future<List<FileInfo>> loadFiles(String path) async {
    try {
      final files = await listFiles(path);
      Logger.instance.d('Loaded ${files.length} files from $path');
      return files;
    } catch (e) {
      Logger.instance.e('Error loading files', e);
      return [];
    }
  }

  /// 获取指定路径下的所有文件和文件夹信息
  Future<List<FileInfo>> listFiles(String directoryPath) async {
    try {
      // 添加权限检查日志
      Logger.instance.d('Checking storage permissions...');
      if (!await requestStoragePermission()) {
        Logger.instance.e('Storage permission denied');
        throw Exception('Storage permission denied');
      }
      Logger.instance.d('Storage permission granted');

      final directory = io.Directory(directoryPath);
      
      if (!await directory.exists()) {
        Logger.instance.e('Directory does not exist: $directoryPath');
        throw Exception('Directory does not exist: $directoryPath');
      }

      Logger.instance.d('Starting to list directory: $directoryPath');
      List<FileInfo> files = [];
      
      await for (final entity in directory.list()) {
        Logger.instance.d('Raw entity path: ${entity.path}, type: ${entity.runtimeType}');
        final name = path.basename(entity.path);
        final isFile = entity is io.File;
        
        Logger.instance.d('Found entity - name: $name, isFile: $isFile');
        if (name.startsWith('.')) continue;
        
        files.add(FileInfo(
          name: name,
          path: entity.path,
          isFile: isFile,
          extension: isFile ? path.extension(entity.path) : null,
        ));
      }

      // 按照文件夹在前，文件在后，然后按名称排序
      files.sort((a, b) {
        if (a.isFile == b.isFile) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        return a.isFile ? 1 : -1;
      });

      Logger.instance.i('Listed ${files.length} files in $directoryPath');
      return files;
    } catch (e) {
      Logger.instance.e('Error listing files', e);
      throw Exception('Error listing files: $e');
    }
  }

  /// 检查文件或目录是否存在
  static Future<bool> exists(String path) async {
    final exists = await io.File(path).exists();
    Logger.instance.d('Checking if file exists: $path - $exists');
    return exists;
  }

  /// 获取文件大小（以字节为单位）
  Future<int> getFileSize(String filePath) async {
    try {
      final file = io.File(filePath);
      final size = await file.length();
      Logger.instance.d('File size for $filePath: $size bytes');
      return size;
    } catch (e) {
      Logger.instance.e('Error getting file size', e);
      throw Exception('Error getting file size: $e');
    }
  }

  /// 获取格式化的文件大小
  String getFormattedSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    final result = '${size.toStringAsFixed(2)} ${suffixes[i]}';
    Logger.instance.d('Formatted size: $bytes bytes -> $result');
    return result;
  }

  /// 创建文件或文件夹
  Future<void> createFileOrFolder(String path, bool isFolder) async {
    try {
      if (isFolder) {
        final directory = io.Directory(path);
        await directory.create(recursive: true);
        Logger.instance.d('Folder created: $path');
      } else {
        final file = io.File(path);
        await file.create(recursive: true);
        Logger.instance.d('File created: $path');
      }
    } catch (e) {
      Logger.instance.e('Error creating file or folder: $path', e);
      throw Exception('Error creating file or folder: $e');
    }
  }
} 