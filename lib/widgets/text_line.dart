import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/text_settings.dart';
import '../utils/logger.dart';
import 'dart:math' as math;

class TextLine extends StatelessWidget {
  final String text;
  final TextSettings settings;
  final bool isFirstLine;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;
  final int lineNumber;

  const TextLine({
    super.key,
    required this.text,
    required this.settings,
    required this.isFirstLine,
    required this.lineNumber,
    this.contextMenuBuilder,
  });

  TextStyle _getTextStyle() {
    return TextStyle(
      fontSize: settings.fontSize,
      height: settings.lineHeight,
      color: settings.textColor,
      fontWeight: settings.isBold ? FontWeight.bold : FontWeight.normal,
      decoration: TextDecoration.none,
      fontFamily: settings.fontFamily,
    );
  }

  TextSpan _buildTextSpan(String text, TextStyle baseStyle) {
    if (!isFirstLine) {
      return TextSpan(text: text, style: baseStyle);
    }

    List<TextSpan> children = [];

    if (settings.firstLineSpaces > 0) {
      children.add(TextSpan(
        text: ' ' * settings.firstLineSpaces,
        style: baseStyle,
      ));
    }

    if (settings.enlargeFirstLetter && text.isNotEmpty) {
      children.add(TextSpan(
        text: text[0],
        style: baseStyle.copyWith(fontSize: baseStyle.fontSize! * 1.5),
      ));
      if (text.length > 1) {
        children.add(TextSpan(text: text.substring(1), style: baseStyle));
      }
    } else {
      children.add(TextSpan(text: text, style: baseStyle));
    }

    return TextSpan(children: children);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = _getTextStyle();
    final textSpan = _buildTextSpan(text, textStyle);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: 1,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);

        double textStartX = 0;
        if (isFirstLine && settings.firstLineSpaces > 0) {
          final spacePainter = TextPainter(
            text: TextSpan(
              text: ' ' * settings.firstLineSpaces,
              style: textStyle,
            ),
            textDirection: TextDirection.ltr,
          );
          spacePainter.layout();
          textStartX = spacePainter.width - (settings.firstLineSpaces * 0.5);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText.rich(
              textSpan,
              contextMenuBuilder: contextMenuBuilder,
              maxLines: 1,
            ),
            CustomPaint(
              size: Size(constraints.maxWidth, 3),
              painter: DashedLinePainter(
                color: settings.textColor,
                dashWidth: 2,
                dashSpace: 2,
                strokeWidth: 0.5,
                startX: textStartX,
                endX: textPainter.width,
              ),
            ),
          ],
        );
      },
    );
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