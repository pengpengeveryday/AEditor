import 'package:flutter/material.dart';
import '../models/text_settings.dart';
import 'text_line.dart';

class BlockText extends StatefulWidget {
  final String text;
  final TextSettings settings;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;

  const BlockText({
    super.key,
    required this.text,
    required this.settings,
    this.contextMenuBuilder,
  });

  @override
  State<BlockText> createState() => _BlockTextState();
}

class _BlockTextState extends State<BlockText> {
  final List<String> _lines = [];
  bool _isLayoutComplete = false;

  @override
  void initState() {
    super.initState();
    _lines.add(widget.text);  // 初始时只添加一行
  }

  void _onLineLayout(int index, int charsUsed) {
    if (_isLayoutComplete || index >= _lines.length) return;
    
    final currentText = _lines[index];
    if (charsUsed < currentText.length) {
      setState(() {
        // 更新当前行
        _lines[index] = currentText.substring(0, charsUsed);
        // 添加新行
        if (index == _lines.length - 1) {
          _lines.add(currentText.substring(charsUsed));
        }
      });
    } else if (index == _lines.length - 1) {
      // 最后一行已完全显示，标记布局完成
      _isLayoutComplete = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: widget.settings.paragraphSpacing * 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_lines.length, (index) {
          return TextLine(
            key: ValueKey('line_${widget.text.hashCode}_$index'),
            text: _lines[index],
            settings: widget.settings,
            isFirstLine: index == 0,
            lineNumber: index + 1,
            contextMenuBuilder: widget.contextMenuBuilder,
            onLineLayout: (charsUsed) => _onLineLayout(index, charsUsed),
          );
        }),
      ),
    );
  }

  @override
  void didUpdateWidget(BlockText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      setState(() {
        _lines.clear();
        _lines.add(widget.text);
        _isLayoutComplete = false;
      });
    }
  }
} 