class Logger {
  static final Logger _instance = Logger._();
  
  static Logger get instance => _instance;
  
  Logger._();

  static const String TAG = "[AEditor]";
  static bool _enableLog = true;

  void d(String message) {
    if (_enableLog) {
      print("$TAG [DEBUG] $message");
    }
  }

  void i(String message) {
    if (_enableLog) {
      print("$TAG [INFO] $message");
    }
  }

  void w(String message) {
    if (_enableLog) {
      print("$TAG [WARN] $message");
    }
  }

  void e(String message, [dynamic error]) {
    if (_enableLog) {
      print("$TAG [ERROR] $message");
      if (error != null) print("$TAG [ERROR] $error");
    }
  }
} 