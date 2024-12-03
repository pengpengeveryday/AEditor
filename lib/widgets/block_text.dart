import 'package:flutter/material.dart';
import '../models/text_settings.dart';
import '../utils/logger.dart';

class BlockText extends StatefulWidget {
  final String text;
  final TextSettings settings;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;
  final Function(TextSettings)? onSettingsChanged;

  const BlockText({
    Key? key,
    required this.text,
    required this.settings,
    this.contextMenuBuilder,
    this.onSettingsChanged,
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

  void _handleSettingsChanged(TextSettings newSettings) {
    if (widget.onSettingsChanged != null) {
      widget.onSettingsChanged!(newSettings);
    }
  }

  String _processText(String text) {
    if (text.isEmpty) return text;

    String processedText = text;
    
    // 处理首字母大写
    if (widget.settings.enlargeFirstLetter && text.isNotEmpty) {
      processedText = text[0].toUpperCase() + text.substring(1);
    }

    // 处理首行缩进
    if (widget.settings.firstLineSpaces > 0) {
      processedText = ' ' * widget.settings.firstLineSpaces + processedText;
    }

    return processedText;
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

    final processedText = _processText(widget.text);

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
            processedText,
            style: textStyle,
            contextMenuBuilder: widget.contextMenuBuilder ?? (context, editableTextState) {
              return AdaptiveTextSelectionToolbar.editableText(
                editableTextState: editableTextState,
              );
            },
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

    final linesToDraw = lineCount - 1;
    if (linesToDraw <= 0) return;

    double currentY = lineHeight - 4;
    double startX = 0;
    while (startX < maxWidth) {
      final dashEndX = (startX + 2).clamp(startX, maxWidth);
      canvas.drawLine(
        Offset(startX, currentY),
        Offset(dashEndX, currentY),
        paint,
      );
      startX += 4;
    }

    for (int i = 1; i < linesToDraw; i++) {
      currentY += lineHeight;
      startX = 0;
      while (startX < maxWidth) {
        final dashEndX = (startX + 2).clamp(startX, maxWidth);
        canvas.drawLine(
          Offset(startX, currentY),
          Offset(dashEndX, currentY),
          paint,
        );
        startX += 4;
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