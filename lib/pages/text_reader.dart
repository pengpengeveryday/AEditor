import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadContent();
    _saveReadingFile();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // 添加滚动监听器，实时保存进度
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    // 确保在页面关闭时保存最终进度
    _saveCurrentProgress();
    _scrollController.removeListener(_handleScroll);
    Settings.instance.setCurrentReadingTextFile(null);
    Logger.instance.d('Cleared current reading text file');
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scrollController.dispose();
    super.dispose();
  }

  // 处理滚动事件，节流保存
  DateTime _lastSave = DateTime.now();
  void _handleScroll() {
    final now = DateTime.now();
    if (now.difference(_lastSave) > const Duration(seconds: 1)) {
      _saveCurrentProgress();
      _lastSave = now;
    }
  }

  Future<void> _saveReadingFile() async {
    await Settings.instance.setCurrentReadingTextFile(widget.filePath);
    Logger.instance.d('Saved current reading text file: ${widget.filePath}');
  }

  Future<void> _loadContent() async {
    try {
      final file = File(widget.filePath);
      final content = await file.readAsString();
      setState(() {
        _content = content;
        _isLoading = false;
      });
      
      // 内容加载完成后，恢复阅读进度
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreReadingProgress();
      });
    } catch (e) {
      Logger.instance.e('Error loading file content', e);
      setState(() {
        _content = 'Error loading file content: $e';
        _isLoading = false;
      });
    }
  }

  void _restoreReadingProgress() {
    if (!_scrollController.hasClients) return;
    
    final progress = Settings.instance.getReadingProgress(widget.filePath);
    Logger.instance.d('Restoring reading progress: $progress');
    
    if (progress > 0 && _scrollController.position.maxScrollExtent > 0) {
      final targetOffset = _scrollController.position.maxScrollExtent * progress;
      _scrollController.jumpTo(targetOffset);
      Logger.instance.d('Jumped to offset: $targetOffset');
    }
  }

  Future<void> _saveCurrentProgress() async {
    if (!_scrollController.hasClients || 
        _scrollController.position.maxScrollExtent <= 0) return;
    
    final progress = _scrollController.offset / _scrollController.position.maxScrollExtent;
    await Settings.instance.saveReadingProgress(widget.filePath, progress);
    Logger.instance.d('Saved reading progress: $progress');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () async {
          // 退出前保存进度
          await _saveCurrentProgress();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : SingleChildScrollView(
                controller: _scrollController,
                child: SelectableText(
                  _content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
      ),
    );
  }
} 