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
  _BlockTextState createState() => _BlockTextState();
}

class _BlockTextState extends State<BlockText> {
  final GlobalKey _key = GlobalKey();

  void _logWidgetSize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;
        Logger.instance.i('BlockText actual widget size - height: ${size.height}, width: ${size.width}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _logWidgetSize();

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
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.settings.textColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: SelectableText(
        widget.text,
        style: textStyle,
        contextMenuBuilder: widget.contextMenuBuilder,
      ),
    );
  }
}