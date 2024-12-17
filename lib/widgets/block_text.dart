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
  String? _pendingText;
  bool _showedDialog = false;

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController(text: widget.text);
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logWidgetSize();
    });
    _tapSubscription = widget.onGlobalTap?.listen((_) {
      if (_isEditing && !_isExiting) {
        Logger.instance.d('BlockText: Global tap detected, triggering confirm exit mode.');
        _confirmExitEditMode();
      }
    });
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _editingController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    Logger.instance.d('BlockText: Focus changed, hasFocus: ${_focusNode.hasFocus}');
    if (!_focusNode.hasFocus && _isEditing && !_isExiting) {
      Logger.instance.d('BlockText: Lost focus while editing, but letting global tap handle it');
    }
  }

  Future<void> _confirmExitEditMode() async {
    if (_isExiting) {
      Logger.instance.d('BlockText: Already exiting, skip confirm dialog');
      return;
    }
    
    _isExiting = true;
    Logger.instance.d('BlockText: Starting confirm exit mode');
    
    // 先隐藏键盘
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    
    try {
      if (_editingController.text != widget.text) {
        final shouldSave = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: const Text('保存更改?', 
                style: TextStyle(color: Colors.white),
              ),
              content: const Text('您想保存对文本的更改吗？',
                style: TextStyle(color: Colors.white),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Logger.instance.d('BlockText: User chose to discard changes');
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('否', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () {
                    Logger.instance.d('BlockText: User chose to save changes');
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('是', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );

        Logger.instance.d('BlockText: Dialog result: $shouldSave');
        
        if (shouldSave == true) {
          widget.onTextChanged?.call(_editingController.text);
          Logger.instance.d('BlockText: Changes saved');
        } else {
          _editingController.text = widget.text;  // 恢复原始文本
          Logger.instance.d('BlockText: Changes discarded');
        }
      }

      setState(() {
        _isEditing = false;  // 退出编辑模式
      });
    } catch (e) {
      Logger.instance.e('BlockText: Error in confirm dialog', e);
    } finally {
      _isExiting = false;
      Logger.instance.d('BlockText: Exit mode completed');
    }
  }

  void _startEditing() {
    if (!widget.settings.allowEditing) return;
    
    Logger.instance.d('BlockText: Starting edit mode');
    setState(() {
      _isEditing = true;
      _editingController.text = widget.text;
    });

    Future.delayed(Duration.zero, () {
      _focusNode.requestFocus();
      Logger.instance.d('BlockText: Requested focus for editing');
    });
  }

  Future<void> _stopEditing() async {
    if (!_isEditing) return;
    
    Logger.instance.d('BlockText: Stopping edit mode');
    
    if (_editingController.text != widget.text) {
      // 如果文本有变化，显示确认话框
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

      if (shouldSave == true) {
        widget.onTextChanged?.call(_editingController.text);
      } else {
        _editingController.text = widget.text;
      }
    }
    
    setState(() {
      _isEditing = false;
      _isExiting = false;
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
    if (_isEditing) {
      return WillPopScope(
        onWillPop: () async {
          Logger.instance.d('BlockText: Back button pressed while editing');
          await _confirmExitEditMode();
          // 在编辑模式下，手势退出永远返回 false，不退出页面
          return false; // 确保不退出页面
        },
        child: TextField(
          controller: _editingController,
          focusNode: _focusNode,
          autofocus: true,
          style: TextStyle(
            fontSize: widget.settings.fontSize,
            color: widget.settings.textColor,
            fontWeight: widget.settings.isBold ? FontWeight.bold : FontWeight.normal,
            height: widget.settings.lineHeight,
            decoration: widget.settings.hasUnderline ? TextDecoration.underline : TextDecoration.none,
            fontFamily: widget.settings.fontFamily,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          maxLines: null,
          onChanged: (value) {
            _pendingText = value;
            Logger.instance.d('BlockText: Text changed, pending: "$value"');
          },
        ),
      );
    }

    final textStyle = TextStyle(
      fontSize: widget.settings.fontSize,
      color: widget.settings.textColor,
      fontWeight: widget.settings.isBold ? FontWeight.bold : FontWeight.normal,
      height: widget.settings.lineHeight,
      decoration: widget.settings.hasUnderline ? TextDecoration.underline : TextDecoration.none,
      fontFamily: widget.settings.fontFamily,
    );

    final text = '${' ' * widget.settings.firstLineSpaces}${widget.text}';

    return GestureDetector(
      onLongPressStart: (LongPressStartDetails details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final halfWidth = box.size.width / 2;
        
        Logger.instance.d('BlockText: Long press detected at (${localPosition.dx}, ${localPosition.dy})');
        Logger.instance.d('BlockText: Text block width: ${box.size.width}, half width: $halfWidth');
        
        if (localPosition.dx > halfWidth) {
          Logger.instance.d('BlockText: Long press on right half, entering edit mode');
          _startEditing();
        } else {
          Logger.instance.d('BlockText: Long press on left half, showing options dialog');
          _showOptionsDialog(context);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: widget.settings.paragraphSpacing,
        ),
        child: widget.settings.enlargeFirstLetter && widget.text.isNotEmpty
            ? RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: text[0],
                      style: textStyle.copyWith(fontSize: widget.settings.fontSize * 1.5),
                    ),
                    TextSpan(
                      text: text.substring(1),
                      style: textStyle,
                    ),
                  ],
                ),
              )
            : Text(
                text,
                style: textStyle,
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