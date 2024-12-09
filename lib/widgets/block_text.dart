import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
  bool _isEditing = false;
  late TextEditingController _editingController;

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController(text: widget.text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logWidgetSize();
    });
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (widget.settings.allowEditing) {
      setState(() {
        _isEditing = true;
      });
    }
  }

  void _stopEditing() {
    setState(() {
      _isEditing = false;
    });
    // TODO: 处理文本改的回调
  }

  void _logWidgetSize() {
    final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final firstLineHeight = widget.settings.enlargeFirstLetter
          ? widget.settings.fontSize * 1.5 * widget.settings.lineHeight
          : widget.settings.fontSize * widget.settings.lineHeight;
      final otherLineHeight = widget.settings.fontSize * widget.settings.lineHeight;
      final lineCount = ((size.height - firstLineHeight) / otherLineHeight).ceil() + 1;
      if (mounted && lineCount != _lineCount) {
        setState(() {
          _lineCount = lineCount;
        });
      }
      
      Logger.instance.i('BlockText size - height: ${size.height}, '
          'first line height: $firstLineHeight, '
          'other line height: $otherLineHeight, '
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

    final firstLetterStyle = textStyle.copyWith(
      fontSize: widget.settings.enlargeFirstLetter ? widget.settings.fontSize * 1.5 : widget.settings.fontSize,
    );

    final indent = ' ' * widget.settings.firstLineSpaces;

    return Container(
      key: _key,
      child: Stack(
        children: [
          if (widget.settings.hasUnderline && _lineCount > 0)
            LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: DashedUnderlinePainter(
                    firstLineHeight: widget.settings.enlargeFirstLetter
                        ? widget.settings.fontSize * 1.5 * widget.settings.lineHeight
                        : widget.settings.fontSize * widget.settings.lineHeight,
                    otherLineHeight: widget.settings.fontSize * widget.settings.lineHeight,
                    maxWidth: constraints.maxWidth,
                    color: widget.settings.textColor,
                    lineCount: _lineCount,
                  ),
                );
              },
            ),
          SelectableText.rich(
            TextSpan(
              children: [
                if (widget.text.isNotEmpty)
                  TextSpan(
                    text: indent + widget.text[0],
                    style: firstLetterStyle,
                  ),
                if (widget.text.length > 1)
                  TextSpan(
                    text: widget.text.substring(1),
                    style: textStyle,
                  ),
                if (widget.settings.allowEditing)
                  TextSpan(
                    text: ' 编辑',
                    style: textStyle.copyWith(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        _startEditing();
                      },
                  ),
              ],
            ),
            contextMenuBuilder: widget.contextMenuBuilder ?? (context, editableTextState) {
              return AdaptiveTextSelectionToolbar.editableText(
                editableTextState: editableTextState,
              );
            },
          ),
          if (widget.settings.allowEditing && _isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextField(
                controller: _editingController,
                style: textStyle,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.settings.textColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.settings.textColor.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.settings.textColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                maxLines: null,
                onSubmitted: (_) => _stopEditing(),
                onEditingComplete: _stopEditing,
              ),
            ),
        ],
      ),
    );
  }
}

class DashedUnderlinePainter extends CustomPainter {
  final double firstLineHeight;
  final double otherLineHeight;
  final double maxWidth;
  final Color color;
  final int lineCount;

  DashedUnderlinePainter({
    required this.firstLineHeight,
    required this.otherLineHeight,
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

    double currentY = firstLineHeight - 4;
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
      currentY += otherLineHeight;
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
    return firstLineHeight != oldDelegate.firstLineHeight ||
           otherLineHeight != oldDelegate.otherLineHeight ||
           maxWidth != oldDelegate.maxWidth ||
           color != oldDelegate.color ||
           lineCount != oldDelegate.lineCount;
  }
}