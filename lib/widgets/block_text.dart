import 'package:flutter/material.dart';
import '../models/text_settings.dart';
import '../utils/logger.dart';

class BlockText extends StatefulWidget {
  final String text;
  final TextSettings settings;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;

  const BlockText({
    Key? key,
    required this.text,
    required this.settings,
    this.contextMenuBuilder,
  }) : super(key: key);

  @override
  State<BlockText> createState() => _BlockTextState();
}

class _BlockTextState extends State<BlockText> {
  final GlobalKey _key = GlobalKey();
  int _lineCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logWidgetSize();
    });
  }

  void _logWidgetSize() {
    final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final lineHeight = widget.settings.fontSize * widget.settings.lineHeight;
      final lineCount = (size.height / lineHeight).floor();
      if (mounted && lineCount != _lineCount) {
        setState(() {
          _lineCount = lineCount;
        });
      }
      
      Logger.instance.i('BlockText size - height: ${size.height}, '
          'line height: $lineHeight, '
          'total lines: $lineCount');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: widget.settings.fontSize,
      height: widget.settings.lineHeight,
      color: widget.settings.textColor,
      fontWeight: widget.settings.isBold ? FontWeight.bold : FontWeight.normal,
      decoration: TextDecoration.none,
      fontFamily: widget.settings.fontFamily,
    );

    return Container(
      key: _key,
      margin: EdgeInsets.only(bottom: widget.settings.paragraphSpacing * 16.0),
      child: Stack(
        children: [
          if (widget.settings.hasUnderline && _lineCount > 0)
            LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: DashedUnderlinePainter(
                    lineHeight: widget.settings.fontSize * widget.settings.lineHeight,
                    maxWidth: constraints.maxWidth,
                    color: widget.settings.textColor,
                    lineCount: _lineCount,
                  ),
                );
              },
            ),
          SelectableText(
            widget.text,
            style: textStyle,
            contextMenuBuilder: widget.contextMenuBuilder,
          ),
        ],
      ),
    );
  }
}

class DashedUnderlinePainter extends CustomPainter {
  final double lineHeight;
  final double maxWidth;
  final Color color;
  final int lineCount;

  DashedUnderlinePainter({
    required this.lineHeight,
    required this.maxWidth,
    required this.color,
    required this.lineCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // 遍历每一行，除了最后一行
    for (int i = 0; i < lineCount - 1; i++) {
      double startX = 0;
      final y = lineHeight * (i + 1) - 4;  // 将下划线往上移动4个像素

      // 绘制一行的虚线下划线
      while (startX < maxWidth) {
        final dashEndX = (startX + 2).clamp(startX, maxWidth);
        canvas.drawLine(
          Offset(startX, y),
          Offset(dashEndX, y),
          paint,
        );
        startX += 4;  // 2像素虚线 + 2像素间隔
      }
    }
  }

  @override
  bool shouldRepaint(DashedUnderlinePainter oldDelegate) {
    return lineHeight != oldDelegate.lineHeight ||
           maxWidth != oldDelegate.maxWidth ||
           color != oldDelegate.color ||
           lineCount != oldDelegate.lineCount;
  }
}