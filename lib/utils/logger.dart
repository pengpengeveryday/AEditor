import 'package:flutter/foundation.dart';

class Logger {
  static Logger? _instance;
  static const String _tag = 'AEditor';

  Logger._();

  static Logger get instance {
    _instance ??= Logger._();
    return _instance!;
  }

  String _formatMessage(String message) {
    return '[$_tag] ${DateTime.now().toString().split('.').first} $message';
  }

  void d(String message, [dynamic error]) {
    if (kDebugMode) {
      print('\x1B[34m[D] ${_formatMessage(message)}\x1B[0m'); // 蓝色
      if (error != null) print(error);
    }
  }

  void i(String message, [dynamic error]) {
    if (kDebugMode) {
      print('\x1B[32m[I] ${_formatMessage(message)}\x1B[0m'); // 绿色
      if (error != null) print(error);
    }
  }

  void w(String message, [dynamic error]) {
    if (kDebugMode) {
      print('\x1B[33m[W] ${_formatMessage(message)}\x1B[0m'); // 黄色
      if (error != null) print(error);
    }
  }

  void e(String message, [dynamic error]) {
    if (kDebugMode) {
      print('\x1B[31m[E] ${_formatMessage(message)}\x1B[0m'); // 红色
      if (error != null) print(error);
    }
  }
} 