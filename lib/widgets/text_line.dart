import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/text_settings.dart';
import '../utils/logger.dart';
import 'dart:math' as math;

class TextLine extends StatefulWidget {
  final String text;
  final TextSettings settings;
  final bool isFirstLine;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;
  final Function(int charsUsed)? onLineLayout;
  final int lineNumber;

  const TextLine({
    super.key,
    required this.text,
    required this.settings,
    required this.isFirstLine,
    required this.lineNumber,
    this.contextMenuBuilder,
    this.onLineLayout,
  });

  @override
  State<TextLine> createState() => _TextLineState();
}

class _TextLineState extends State<TextLine> {
  bool _hasNotifiedLayout = false;
  late double _textStartX;
  late double _textEndX;

  TextStyle _getTextStyle() {
    return TextStyle(
      fontSize: widget.settings.fontSize,
      height: widget.settings.lineHeight,
      color: widget.settings.textColor,
      fontWeight: widget.settings.isBold ? FontWeight.bold : FontWeight.normal,
      decoration: TextDecoration.none,
      fontFamily: widget.settings.fontFamily,
    );
  }

  TextSpan _buildTextSpan(String text, TextStyle baseStyle) {
    if (!widget.isFirstLine) {
      return TextSpan(text: text, style: baseStyle);
    }

    // 处理首行
    String displayText = text;
    List<TextSpan> children = [];

    // 添加首行空格
    if (widget.settings.firstLineSpaces > 0) {
      children.add(TextSpan(
        text: ' ' * widget.settings.firstLineSpaces,
        style: baseStyle,
      ));
    }

    // 处理首字符大字号
    if (widget.settings.enlargeFirstLetter && displayText.isNotEmpty) {
      children.add(TextSpan(
        text: displayText[0],
        style: baseStyle.copyWith(
          fontSize: baseStyle.fontSize! * 1.5,  // 首字符1.5倍大小
        ),
      ));
      if (displayText.length > 1) {
        children.add(TextSpan(
          text: displayText.substring(1),
          style: baseStyle,
        ));
      }
    } else {
      children.add(TextSpan(
        text: displayText,
        style: baseStyle,
      ));
    }

    return TextSpan(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = _getTextStyle();
        final textSpan = _buildTextSpan(widget.text, textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: 1,
        );
        
        textPainter.layout(maxWidth: constraints.maxWidth);
        
        int start = 0;
        int end = widget.text.length;
        int charsCanFit = 0;
        
        while (start <= end) {
          int mid = (start + end) ~/ 2;
          textPainter.text = _buildTextSpan(
            widget.text.substring(0, mid),
            textStyle,
          );
          textPainter.layout(maxWidth: constraints.maxWidth);
          
          if (textPainter.didExceedMaxLines) {
            end = mid - 1;
          } else {
            charsCanFit = mid;
            start = mid + 1;
          }
        }
        
        final remainingChars = widget.text.length - charsCanFit;
        final isLastLine = remainingChars == 0;  // 通过剩余字符判断是否为最后一行

        // 计算实际文本的起始和结束位置
        final fullTextPainter = TextPainter(
          text: _buildTextSpan(widget.text.substring(0, charsCanFit), textStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        );
        fullTextPainter.layout(maxWidth: constraints.maxWidth);

        // 修正首行空格宽度计算
        if (widget.isFirstLine && widget.settings.firstLineSpaces > 0) {
          final spacePainter = TextPainter(
            text: TextSpan(
              text: ' ' * widget.settings.firstLineSpaces,
              style: textStyle,
            ),
            textDirection: TextDirection.ltr,
          );
          spacePainter.layout();
          _textStartX = spacePainter.width - (widget.settings.firstLineSpaces * 0.5);
        } else {
          _textStartX = 0;
        }
        
        // 设置下划线结束位置
        _textEndX = isLastLine ? fullTextPainter.width : constraints.maxWidth;

        if (!_hasNotifiedLayout && widget.onLineLayout != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onLineLayout?.call(charsCanFit);
            _hasNotifiedLayout = true;
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText.rich(
              _buildTextSpan(
                widget.text.substring(0, charsCanFit),
                textStyle,
              ),
              contextMenuBuilder: widget.contextMenuBuilder,
              maxLines: 1,
            ),
            CustomPaint(
              size: Size(constraints.maxWidth, 3),
              painter: DashedLinePainter(
                color: widget.settings.textColor,
                dashWidth: 2,
                dashSpace: 2,
                strokeWidth: 0.5,
                startX: _textStartX,
                endX: _textEndX,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void didUpdateWidget(TextLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _hasNotifiedLayout = false;
    }
  }
}

// 虚线画笔
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;
  final double startX;
  final double endX;

  DashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
    required this.startX,
    required this.endX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double currentX = startX;
    final y = size.height / 2;

    while (currentX < endX) {
      final lineEndX = math.min(currentX + dashWidth, endX);
      canvas.drawLine(
        Offset(currentX, y),
        Offset(lineEndX, y),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) {
    return color != oldDelegate.color ||
           dashWidth != oldDelegate.dashWidth ||
           dashSpace != oldDelegate.dashSpace ||
           strokeWidth != oldDelegate.strokeWidth ||
           startX != oldDelegate.startX ||
           endX != oldDelegate.endX;
  }
} 