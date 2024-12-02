import 'package:flutter/material.dart';
import '../models/text_settings.dart';
import 'text_line.dart';
import 'dart:math' as math;

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
  static const int _batchSize = 20;  // 每批处理的行数
  int _processedLength = 0;
  
  void _calculateNextBatch(BuildContext context, String text, double maxWidth) {
    if (_processedLength >= text.length) return;
    
    final textStyle = TextStyle(
      fontSize: widget.settings.fontSize,
      height: widget.settings.lineHeight,
      color: widget.settings.textColor,
      fontWeight: widget.settings.isBold ? FontWeight.bold : FontWeight.normal,
      decoration: TextDecoration.none,
      fontFamily: widget.settings.fontFamily,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    String remainingText = text.substring(_processedLength);
    bool isFirstLine = _lines.isEmpty;
    int processedInBatch = 0;
    
    while (remainingText.isNotEmpty && processedInBatch < _batchSize) {
      TextSpan textSpan;
      if (isFirstLine) {
        List<TextSpan> children = [];
        if (widget.settings.firstLineSpaces > 0) {
          children.add(TextSpan(
            text: ' ' * widget.settings.firstLineSpaces,
            style: textStyle,
          ));
        }
        
        children.add(TextSpan(
          text: remainingText,
          style: textStyle,
        ));
        textSpan = TextSpan(children: children);
      } else {
        textSpan = TextSpan(text: remainingText, style: textStyle);
      }

      textPainter.text = textSpan;
      
      // 优化二分查找，使用估算的初始值
      int estimatedChars = (maxWidth / (textStyle.fontSize! * 1.2)).floor();
      estimatedChars = estimatedChars.clamp(1, remainingText.length);
      
      int start = estimatedChars ~/ 2;
      int end = math.min(estimatedChars * 2, remainingText.length);
      int charsCanFit = 0;

      while (start <= end) {
        int mid = (start + end) ~/ 2;
        if (isFirstLine) {
          List<TextSpan> children = [];
          if (widget.settings.firstLineSpaces > 0) {
            children.add(TextSpan(
              text: ' ' * widget.settings.firstLineSpaces,
              style: textStyle,
            ));
          }
          children.add(TextSpan(
            text: remainingText.substring(0, mid),
            style: textStyle,
          ));
          textPainter.text = TextSpan(children: children);
        } else {
          textPainter.text = TextSpan(
            text: remainingText.substring(0, mid),
            style: textStyle,
          );
        }
        
        textPainter.layout(maxWidth: maxWidth);

        if (textPainter.didExceedMaxLines) {
          end = mid - 1;
        } else {
          charsCanFit = mid;
          start = mid + 1;
        }
      }

      if (charsCanFit > 0) {
        _lines.add(remainingText.substring(0, charsCanFit));
        remainingText = remainingText.substring(charsCanFit);
        _processedLength += charsCanFit;
        processedInBatch++;
        isFirstLine = false;
      } else {
        break;
      }
    }

    if (remainingText.isNotEmpty) {
      // 还有未处理的文本，安排下一帧继续处理
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _calculateNextBatch(context, text, maxWidth);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lines.isEmpty) {
      _calculateNextBatch(context, widget.text, MediaQuery.of(context).size.width);
    }

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
          );
        }),
      ),
    );
  }

  @override
  void didUpdateWidget(BlockText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.settings != widget.settings) {
      setState(() {
        _lines.clear();
        _processedLength = 0;
      });
    }
  }
} 