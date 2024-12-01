import 'package:flutter/material.dart';
import '../models/text_settings.dart';

class TextLine extends StatelessWidget {
  final String text;
  final TextSettings settings;
  final bool isFirstLine;  // 是否是段落的第一行
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;

  const TextLine({
    super.key,
    required this.text,
    required this.settings,
    this.isFirstLine = false,
    this.contextMenuBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // 计算首行缩进
    final spaces = isFirstLine ? ' ' * settings.firstLineSpaces : '';
    final displayText = spaces + text;
    
    // 判断是否需要放大首字符
    final needEnlargeFirst = isFirstLine && settings.enlargeFirstLetter && text.isNotEmpty;
    
    // 基础文本样式
    final baseStyle = TextStyle(
      fontSize: settings.fontSize,
      height: settings.lineHeight,
      color: settings.textColor,
      fontFamily: settings.fontFamily,
      fontWeight: settings.isBold ? FontWeight.bold : FontWeight.normal,
      decoration: settings.hasUnderline ? TextDecoration.underline : TextDecoration.none,
      decorationColor: settings.textColor,
      decorationStyle: TextDecorationStyle.dotted,
      decorationThickness: 0.5,
    );

    return SelectableText.rich(
      TextSpan(
        children: needEnlargeFirst
            ? [
                // 首字符（放大）
                TextSpan(
                  text: spaces + text[0],
                  style: baseStyle.copyWith(
                    fontSize: settings.fontSize * 1.5,
                  ),
                ),
                // 剩余文本
                if (text.length > 1)
                  TextSpan(
                    text: text.substring(1),
                    style: baseStyle,
                  ),
              ]
            : [
                // 普通文本
                TextSpan(
                  text: displayText,
                  style: baseStyle,
                ),
              ],
      ),
      contextMenuBuilder: contextMenuBuilder,
    );
  }
} 