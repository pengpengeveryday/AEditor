import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../utils/logger.dart';
import '../models/settings.dart';
import '../models/text_settings.dart';
import '../widgets/text_settings_dialog.dart';
import '../widgets/rich_text.dart';
import 'package:share_plus/share_plus.dart';

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
  late TextSettings _textSettings;
  
  @override
  void initState() {
    super.initState();
    _loadTextSettings();
    _loadContent();
    _saveReadingFile();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _scrollController.addListener(_handleScroll);
  }

  void _loadTextSettings() {
    final savedSettings = Settings.instance.getTextSettings();
    if (savedSettings != null) {
      setState(() {
        _textSettings = TextSettings.fromJson(savedSettings);
      });
      Logger.instance.d('Loaded global text settings');
    } else {
      _textSettings = TextSettings();  // 使用默认设置
      Logger.instance.d('Using default text settings');
    }
  }

  Future<void> _saveTextSettings() async {
    await Settings.instance.saveTextSettings(_textSettings.toJson());
    Logger.instance.d('Saved global text settings');
  }

  @override
  void dispose() {
    _saveTextSettings();
    _saveCurrentProgress();
    _scrollController.removeListener(_handleScroll);
    Settings.instance.setCurrentReadingTextFile(null);
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => TextSettingsDialog(
        initialSettings: _textSettings,
        onSettingsChanged: (newSettings) {
          setState(() {
            _textSettings = newSettings;
          });
          _saveTextSettings();  // 保存设置
        },
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return ParagraphText(
      text: text,
      settings: _textSettings,  // 传递当前的文本设置
      contextMenuBuilder: _buildContextMenu,
    );
  }

  Widget _buildContextMenu(BuildContext context, EditableTextState editableTextState) {
    final List<ContextMenuButtonItem> buttonItems = 
      editableTextState.contextMenuButtonItems;
    
    buttonItems.add(
      ContextMenuButtonItem(
        label: '设置',
        onPressed: () {
          editableTextState.hideToolbar();
          _showSettingsDialog();
        },
      ),
    );
    
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  List<Widget> _buildParagraphs() {
    // 按换行符分割文本
    final paragraphs = _content.split('\n').where((text) => text.trim().isNotEmpty).toList();
    return paragraphs.map((text) => _buildParagraph(text.trim())).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildParagraphs(),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Opacity(
          opacity: 0.3,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.grey,
            child: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _saveCurrentProgress();
              if (context.mounted) {
                Navigator.of(context).pop();
                // 延迟500ms后通知目录浏览页显示内容
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {});
                  }
                });
              }
            },
          ),
        ),
      ),
    );
  }
} 