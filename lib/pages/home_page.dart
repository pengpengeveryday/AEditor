import 'package:flutter/material.dart';
import '../models/file_manager.dart';
import '../models/settings.dart';
import '../utils/logger.dart';
import 'folder_browser.dart';
import 'package:path/path.dart' as path;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _handleBrowsePressed(BuildContext context) async {
    Logger.instance.d('Navigate to FolderBrowser');
    
    String? lastReadingFile = Settings.instance.currentReadingTextFile;
    if (lastReadingFile != null) {
      String lastReadingDir = path.dirname(lastReadingFile);
      Logger.instance.d('Found last reading directory: $lastReadingDir');
      await Settings.instance.setCurrentPath(lastReadingDir);
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FolderBrowser(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'AEditor',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            side: const BorderSide(color: Colors.white),
          ),
          onPressed: () => _handleBrowsePressed(context),
          child: const Text(
            '查看目录',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
} 