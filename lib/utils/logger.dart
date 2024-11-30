import 'package:flutter/foundation.dart';

class Logger {
  static final Logger _instance = Logger._internal();
  static Logger get instance => _instance;

  Logger._internal();

  String _getTimestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}-'
           '${now.minute.toString().padLeft(2, '0')}-'
           '${now.second.toString().padLeft(2, '0')}:'
           '${now.millisecond.toString().padLeft(3, '0')}';
  }

  void d(String message) {
    if (kDebugMode) {
      print('AEditor [${_getTimestamp()}] [D] $message');
    }
  }

  void i(String message) {
    if (kDebugMode) {
      print('AEditor [${_getTimestamp()}] [I] $message');
    }
  }

  void w(String message) {
    if (kDebugMode) {
      print('AEditor [${_getTimestamp()}] [W] $message');
    }
  }

  void e(String message, [dynamic error]) {
    if (kDebugMode) {
      print('AEditor [${_getTimestamp()}] [E] $message');
      if (error != null) {
        print('AEditor [${_getTimestamp()}] [E] $error');
      }
    }
  }
} 