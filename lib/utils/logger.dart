class Logger {
  static const String _tag = 'AEditor';
  static final Logger _instance = Logger._internal();
  
  factory Logger() {
    return _instance;
  }

  Logger._internal();

  void d(String message) {
    print('$_tag DEBUG: $message');
  }

  void e(String message) {
    print('$_tag ERROR: $message');
  }

  void i(String message) {
    print('$_tag INFO: $message');
  }

  void w(String message) {
    print('$_tag WARN: $message');
  }
} 