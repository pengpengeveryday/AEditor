import 'package:flutter/material.dart';
import 'models/settings.dart';
import 'pages/home_page.dart';
import 'utils/logger.dart';
import 'package:path/path.dart' as path;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Logger.instance.i('Initializing application');
  await Settings.instance.init();
  
  String? lastReadingFile = Settings.instance.currentReadingTextFile;
  if (lastReadingFile != null) {
    String lastReadingDir = path.dirname(lastReadingFile);
    Logger.instance.d('Found last reading file: $lastReadingFile');
    Logger.instance.d('Setting current path to: $lastReadingDir');
    await Settings.instance.setCurrentPath(lastReadingDir);
  } else {
    Logger.instance.d('No previous reading file found');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AEditor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}
