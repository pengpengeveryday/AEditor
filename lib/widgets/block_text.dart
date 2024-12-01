import 'package:flutter/material.dart';
import '../models/text_settings.dart';
import 'text_line.dart';

class BlockText extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: settings.paragraphSpacing * 16.0),
      child: TextLine(
        text: text,
        settings: settings,
        isFirstLine: true,  // 段落文本总是作为第一行处理
        contextMenuBuilder: contextMenuBuilder,
      ),
    );
  }
} 