import 'dart:io' as io;
import 'package:path/path.dart' as path;
import '../utils/logger.dart';

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
    final logger = Logger();
    logger.d('FileInfo{name: $name, path: $path, isFile: $isFile, extension: $extension}');
    return 'FileInfo{name: $name, path: $path, isFile: $isFile, extension: $extension}';
  }
}

class FileManager {
  final _logger = Logger();
  
  // 单例模式
  static final FileManager _instance = FileManager._internal();
  
  factory FileManager() {
    return _instance;
  }

  FileManager._internal();

  /// 获取指定路径下的所有文件和文件夹信息
  Future<List<FileInfo>> listFiles(String directoryPath) async {
    try {
      final directory = io.Directory(directoryPath);
      
      if (!await directory.exists()) {
        _logger.e('Directory does not exist: $directoryPath');
        throw Exception('Directory does not exist: $directoryPath');
      }

      List<FileInfo> files = [];
      
      await for (final entity in directory.list(recursive: false)) {
        final name = path.basename(entity.path);
        final isFile = entity is io.File;
        
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

      _logger.i('Listed ${files.length} files in $directoryPath');
      return files;
    } catch (e) {
      _logger.e('Error listing files: $e');
      throw Exception('Error listing files: $e');
    }
  }

  /// 检查文件或目录是否存在
  static Future<bool> exists(String path) async {
    final logger = Logger();
    final exists = await io.File(path).exists();
    logger.d('Checking if file exists: $path - $exists');
    return exists;
  }

  /// 获取文件大小（以字节为单位）
  Future<int> getFileSize(String filePath) async {
    try {
      final file = io.File(filePath);
      final size = await file.length();
      _logger.d('File size for $filePath: $size bytes');
      return size;
    } catch (e) {
      _logger.e('Error getting file size: $e');
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
    _logger.d('Formatted size: $bytes bytes -> $result');
    return result;
  }
} 