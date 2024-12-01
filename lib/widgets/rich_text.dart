import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/text_settings.dart';

class ParagraphText extends StatelessWidget {
  final String text;
  final TextSettings settings;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;

  const ParagraphText({
    super.key,
    required this.text,
    required this.settings,
    this.contextMenuBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final spaces = ' ' * settings.firstLineSpaces;
    
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

    return Container(
      margin: EdgeInsets.only(bottom: settings.paragraphSpacing * 16.0),
      child: SelectableText.rich(
        TextSpan(
          children: text.isNotEmpty && settings.enlargeFirstLetter
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
                  // 不放大的情况
                  TextSpan(
                    text: spaces + text,
                    style: baseStyle,
                  ),
                ],
        ),
        contextMenuBuilder: contextMenuBuilder,
      ),
    );
  }
} 