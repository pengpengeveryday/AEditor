import 'package:flutter/material.dart';
import 'dart:io';
import '../utils/logger.dart';
import '../model/settings.dart';

class TextReader extends StatefulWidget {
  final String filePath;

  const TextReader({
    super.key,
    required this.filePath,
  });

  @override
  State<TextReader> createState() => _TextReaderState();
}

class _TextReaderState extends State<TextReader> {
  String _content = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _saveReadingFile();
  }

  Future<void> _saveReadingFile() async {
    await Settings.instance.setCurrentReadingTextFile(widget.filePath);
    Logger.instance.d('Saved current reading text file: ${widget.filePath}');
  }

  @override
  void dispose() {
    Settings.instance.setCurrentReadingTextFile(null);
    Logger.instance.d('Cleared current reading text file');
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      final file = File(widget.filePath);
      final content = await file.readAsString();
      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      Logger.instance.e('Error loading file content', e);
      setState(() {
        _content = 'Error loading file content: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.filePath.split('/').last,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // TODO: 实现更多选项菜单
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                _content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
    );
  }
} 