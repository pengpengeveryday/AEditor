import 'package:flutter/material.dart';
import '../models/text_settings.dart';
import '../utils/logger.dart';

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = _getTextStyle();
        final textPainter = TextPainter(
          text: TextSpan(
            text: widget.text,
            style: textStyle,
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        );
        
        textPainter.layout(maxWidth: constraints.maxWidth);
        
        int start = 0;
        int end = widget.text.length;
        int charsCanFit = 0;
        
        while (start <= end) {
          int mid = (start + end) ~/ 2;
          textPainter.text = TextSpan(
            text: widget.text.substring(0, mid),
            style: textStyle,
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
        final remainingText = widget.text.substring(charsCanFit);
        
        Logger.instance.d('Line ${widget.lineNumber}: '
            'Total chars: ${widget.text.length}, '
            'Chars displayed: $charsCanFit, '
            'Remaining chars: $remainingChars, '
            'Text: ${widget.text.substring(0, charsCanFit)}, '
            'Remaining text: $remainingText');
        
        if (!_hasNotifiedLayout) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onLineLayout?.call(charsCanFit);
            _hasNotifiedLayout = true;
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: constraints.maxWidth,
              child: Text(
                widget.text.substring(0, charsCanFit),
                style: textStyle,
                overflow: TextOverflow.clip,
                softWrap: false,
              ),
            ),
            CustomPaint(
              size: Size(constraints.maxWidth, 3),
              painter: DashedLinePainter(
                color: widget.settings.textColor,
                dashWidth: 2,
                dashSpace: 2,
                strokeWidth: 0.5,
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

  DashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double currentX = 0;
    final y = size.height / 2;

    while (currentX < size.width) {
      canvas.drawLine(
        Offset(currentX, y),
        Offset(currentX + dashWidth, y),
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
           strokeWidth != oldDelegate.strokeWidth;
  }
} 