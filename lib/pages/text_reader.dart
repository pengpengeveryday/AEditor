import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../utils/logger.dart';
import '../models/settings.dart';
import '../models/text_settings.dart';
import '../widgets/text_settings_dialog.dart';
import '../widgets/block_text.dart';
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
  final _globalTapController = StreamController<void>.broadcast();
  
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
    _globalTapController.close();
    super.dispose();
  }

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
          _saveTextSettings();
        },
      ),
    );
  }

  Future<void> _saveContentToFile() async {
    try {
      final file = File(widget.filePath);
      await file.writeAsString(_content);
      Logger.instance.d('TextReader: Content saved to file: ${widget.filePath}');
    } catch (e) {
      Logger.instance.e('TextReader: Error saving file content', e);
    }
  }

  List<Widget> _buildParagraphs() {
    final paragraphs = _content.split('\n').where((text) => text.trim().isNotEmpty).toList();
    return List.generate(paragraphs.length, (index) {
      final spacing = (index < paragraphs.length - 1 ? _textSettings.paragraphSpacing * 16.0 : 0).toDouble();
      return Padding(
        padding: EdgeInsets.only(bottom: spacing),
        child: BlockText(
          text: paragraphs[index].trim(),
          settings: _textSettings,
          contextMenuBuilder: _buildContextMenu,
          onGlobalTap: _globalTapController.stream,
          onTextChanged: (String newText) {
            Logger.instance.d('TextReader: Updating paragraph content');
            
            // 更新段落内容
            setState(() {
              paragraphs[index] = newText;
              _content = paragraphs.join('\n');
            });

            // 保存到文件
            _saveContentToFile();
          },
        ),
      );
    });
  }

  Widget _buildContextMenu(BuildContext context, EditableTextState editableTextState) {
    final List<ContextMenuButtonItem> buttonItems = 
      editableTextState.contextMenuButtonItems;
    
    buttonItems.insert(0, 
      ContextMenuButtonItem(
        label: '编辑',
        onPressed: () {
          editableTextState.hideToolbar();
          // TODO: 实现编辑功能
        },
      ),
    );
    
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) {
        _globalTapController.add(null);
      },
      child: Scaffold(
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
      ),
    );
  }
} 