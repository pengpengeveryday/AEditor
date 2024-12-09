import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/text_settings.dart';
import '../utils/logger.dart';

class BlockText extends StatefulWidget {
  final String text;
  final TextSettings settings;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;
  final Function(TextSettings)? onSettingsChanged;
  final Function(String)? onTextChanged;
  final Stream<void>? onGlobalTap;

  const BlockText({
    Key? key,
    required this.text,
    required this.settings,
    this.contextMenuBuilder,
    this.onSettingsChanged,
    this.onTextChanged,
    this.onGlobalTap,
  }) : super(key: key);

  @override
  State<BlockText> createState() => _BlockTextState();
}

class _BlockTextState extends State<BlockText> {
  final GlobalKey _key = GlobalKey();
  int _lineCount = 0;
  bool _isEditing = false;
  late TextEditingController _editingController;
  StreamSubscription? _tapSubscription;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController(text: widget.text);
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logWidgetSize();
    });
    _tapSubscription = widget.onGlobalTap?.listen((_) {
      if (_isEditing) {
        Logger.instance.d('BlockText: Global tap detected, exiting edit mode.');
        _stopEditing();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _editingController.dispose();
    _tapSubscription?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    Logger.instance.d('BlockText: Focus changed, hasFocus: ${_focusNode.hasFocus}');
    if (!_focusNode.hasFocus && _isEditing) {
      _confirmExitEditMode();
    }
  }

  Future<void> _confirmExitEditMode() async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('保存更改?'),
          content: Text('您想保存对文本的更改吗？'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);  // 不保存
              },
              child: Text('否'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);  // 保存
              },
              child: Text('是'),
            ),
          ],
        );
      },
    );

    if (shouldSave == true) {
      // 直接从编辑框获取文本并更新
      final newText = _editingController.text;
      if (widget.onTextChanged != null) {
        widget.onTextChanged!(newText);
      }
    } else {
      // 丢弃更改，恢复原文本
      _editingController.text = widget.text;
    }

    setState(() {
      _isEditing = false;
    });
  }

  void _startEditing() {
    if (widget.settings.allowEditing) {
      setState(() {
        _isEditing = true;
        Logger.instance.d('BlockText: Entering edit mode.');
      });
    }
  }

  void _stopEditing() {
    if (widget.onTextChanged != null) {
      widget.onTextChanged!(_editingController.text);
    }
    setState(() {
      _isEditing = false;
      Logger.instance.d('BlockText: Exiting edit mode.');
    });
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

    return WillPopScope(
      onWillPop: () async {
        if (_isEditing) {
          await _confirmExitEditMode();
          return false;
        }
        return true;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          Logger.instance.d('BlockText: Tap detected.');
          if (_isEditing) {
            FocusScope.of(context).unfocus();
            _confirmExitEditMode();
          }
        },
        child: Container(
          key: _key,
          child: Stack(
            children: [
              if (!_isEditing)
                Stack(
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
                                ..onTap = _startEditing,
                            ),
                        ],
                      ),
                      contextMenuBuilder: widget.contextMenuBuilder ?? (context, editableTextState) {
                        return AdaptiveTextSelectionToolbar.editableText(
                          editableTextState: editableTextState,
                        );
                      },
                    ),
                  ],
                ),
              if (_isEditing)
                GestureDetector(
                  onTap: () {
                    Logger.instance.d('BlockText: TextField tapped.');
                  },
                  child: TextField(
                    controller: _editingController,
                    focusNode: _focusNode,
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
                    autofocus: true,
                    onSubmitted: (_) => _stopEditing(),
                    onEditingComplete: _stopEditing,
                  ),
                ),
            ],
          ),
        ),
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