import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/text_settings.dart';
import '../utils/logger.dart';
import '../widgets/text_settings_dialog.dart';

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
  bool _isExiting = false;

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
    if (!_focusNode.hasFocus && _isEditing && !_isExiting) {
      Logger.instance.d('BlockText: Lost focus while editing, triggering exit edit mode');
      _confirmExitEditMode();
    }
  }

  Future<void> _confirmExitEditMode() async {
    if (_isExiting) return;
    _isExiting = true;
    
    try {
      FocusScope.of(context).unfocus();

      if (_editingController.text == widget.text) {
        setState(() {
          _isEditing = false;
        });
        return;
      }

      final shouldSave = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('保存更改?'),
            content: Text('您想保存对文本的更改吗？'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text('否'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text('是'),
              ),
            ],
          );
        },
      );

      if (shouldSave == true && widget.onTextChanged != null) {
        widget.onTextChanged!(_editingController.text);
      } else {
        _editingController.text = widget.text;
      }

      setState(() {
        _isEditing = false;
      });

    } finally {
      _isExiting = false;
    }
  }

  void _startEditing() {
    if (widget.settings.allowEditing) {
      _editingController = TextEditingController(text: widget.text);
      
      setState(() {
        _isEditing = true;
        Logger.instance.d('BlockText: Entering edit mode.');
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNode);
        Logger.instance.d('BlockText: Requesting focus in next frame');
      });
    }
  }

  void _stopEditing() {
    if (widget.onTextChanged != null) {
      widget.onTextChanged!(_editingController.text);
    }
    
    _editingController.dispose();
    
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

  Future<void> _handleGestureExit() async {
    if (_isEditing) {
      final currentText = _editingController.text;
      
      if (currentText == widget.text) {
        FocusScope.of(context).unfocus();
        setState(() {
          _isEditing = false;
        });
        _editingController.dispose();
        return;
      }

      FocusScope.of(context).unfocus();
      setState(() {
        _isEditing = false;
      });
      await _confirmExitEditMode();
    }
  }

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.copy, color: Colors.white),
              title: Text('复制', style: TextStyle(color: Colors.white)),
              onTap: () {
                // 复制操作
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.white),
              title: Text('设置', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => TextSettingsDialog(
                    initialSettings: widget.settings,
                    onSettingsChanged: (newSettings) {
                      // 通过回调通知父组件更新设置
                      widget.onSettingsChanged?.call(newSettings);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        _showOptionsDialog(context);
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: widget.settings.paragraphIndent.toDouble(),
          bottom: widget.settings.paragraphSpacing,
        ),
        child: widget.settings.enlargeFirstLetter && widget.text.isNotEmpty
            ? RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: widget.text[0],
                      style: TextStyle(
                        fontSize: widget.settings.fontSize * 1.5,
                        color: widget.settings.textColor,
                        fontWeight: widget.settings.isBold ? FontWeight.bold : FontWeight.normal,
                        height: widget.settings.lineHeight,
                        decoration: widget.settings.hasUnderline ? TextDecoration.underline : TextDecoration.none,
                        fontFamily: widget.settings.fontFamily,
                      ),
                    ),
                    TextSpan(
                      text: widget.text.substring(1),
                      style: TextStyle(
                        fontSize: widget.settings.fontSize,
                        color: widget.settings.textColor,
                        fontWeight: widget.settings.isBold ? FontWeight.bold : FontWeight.normal,
                        height: widget.settings.lineHeight,
                        decoration: widget.settings.hasUnderline ? TextDecoration.underline : TextDecoration.none,
                        fontFamily: widget.settings.fontFamily,
                      ),
                    ),
                  ],
                ),
              )
            : Text(
                widget.text,
                style: TextStyle(
                  fontSize: widget.settings.fontSize,
                  color: widget.settings.textColor,
                  fontWeight: widget.settings.isBold ? FontWeight.bold : FontWeight.normal,
                  height: widget.settings.lineHeight,
                  decoration: widget.settings.hasUnderline ? TextDecoration.underline : TextDecoration.none,
                  fontFamily: widget.settings.fontFamily,
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