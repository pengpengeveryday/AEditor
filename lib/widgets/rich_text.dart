import 'package:flutter/material.dart';
import '../models/text_settings.dart';
import '../utils/logger.dart';
import 'dart:math';

class ParagraphText extends StatelessWidget {
  final String text;
  final TextSettings settings;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;

  const ParagraphText({
    super.key,
    required this.text,
    required this.settings,
    this.contextMenuBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    // 创建一个 painter 来计算实际高度
    final painter = ParagraphPainter(
      text: text,
      settings: settings,
      hasLargeFirstChar: true,
    );
    
    // 使用 layout builder 获取可用宽度并计算高度
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算行信息
        painter.calculateLines(constraints.maxWidth);
        
        // 计算总高度
        final totalHeight = painter.lines.fold<double>(
          0, 
          (sum, line) => sum + line.height
        );
        
        Logger.instance.d('[ParagraphText] Total height: $totalHeight');
        
        return SizedBox(
          height: totalHeight,
          child: Stack(
            children: [
              SelectableText(
                text,
                style: TextStyle(
                  color: Colors.transparent,
                  fontSize: settings.fontSize,
                  height: settings.lineHeight,
                  fontFamily: settings.fontFamily,
                ),
                contextMenuBuilder: contextMenuBuilder,
              ),
              CustomPaint(
                painter: painter,
                size: Size.fromHeight(totalHeight),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ParagraphPainter extends CustomPainter {
  final String text;
  final TextSettings settings;
  final bool hasLargeFirstChar;
  final List<TextLine> lines = [];
  bool _isLinesCalculated = false;

  ParagraphPainter({
    required this.text,
    required this.settings,
    this.hasLargeFirstChar = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!_isLinesCalculated) {
      calculateLines(size.width);
      _isLinesCalculated = true;
    }

    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());

    double y = 0;
    for (final line in lines) {
      final lineRect = Rect.fromLTWH(0, y, size.width, line.height);
      if (lineRect.overlaps(bounds)) {
        line.textPainter.paint(canvas, Offset(line.x, y));
        
        final paint = Paint()
          ..color = settings.textColor
          ..style = PaintingStyle.fill;
        
        double x = line.x;
        final underlineY = y + line.height - 2;
        
        while (x < line.x + line.width) {
          canvas.drawCircle(
            Offset(x, underlineY),
            0.5,
            paint,
          );
          x += 4;
        }
      }
      
      y += line.height;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(ParagraphPainter oldDelegate) {
    return text != oldDelegate.text || 
           settings != oldDelegate.settings ||
           hasLargeFirstChar != oldDelegate.hasLargeFirstChar;
  }

  @override
  bool shouldRebuildSemantics(ParagraphPainter oldDelegate) => false;

  void calculateLines(double maxWidth) {
    lines.clear();
    String remainingText = text;
    bool isFirstLine = true;
    
    while (remainingText.isNotEmpty) {
      String currentLine = '';
      double currentWidth = 0;
      double x = isFirstLine && settings.firstLineSpaces > 0 
          ? settings.fontSize * settings.firstLineSpaces 
          : 0;
      
      // 处理首行首字符
      if (isFirstLine && hasLargeFirstChar && remainingText.isNotEmpty) {
        final firstChar = remainingText[0];
        final firstCharPainter = TextPainter(
          text: TextSpan(
            text: firstChar,
            style: TextStyle(
              fontSize: settings.fontSize * 1.5,
              color: settings.textColor,
              fontFamily: settings.fontFamily,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        firstCharPainter.layout();
        
        currentWidth = firstCharPainter.width;
        currentLine = firstChar;
        remainingText = remainingText.length > 1 ? remainingText.substring(1) : '';
      }
      
      // 处理当前行剩余文本
      if (remainingText.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: 'A',
            style: TextStyle(
              fontSize: settings.fontSize,
              color: settings.textColor,
              fontFamily: settings.fontFamily,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        for (int i = 0; i < remainingText.length; i++) {
          final char = remainingText[i];
          tp.text = TextSpan(
            text: char,
            style: TextStyle(
              fontSize: settings.fontSize,
              color: settings.textColor,
              fontFamily: settings.fontFamily,
            ),
          );
          tp.layout();
          
          if (x + currentWidth + tp.width > maxWidth) {
            break;
          }
          
          currentWidth += tp.width;
          currentLine += char;
        }
      }
      
      // 确保至少有一个字符
      if (currentLine.isEmpty && remainingText.isNotEmpty) {
        currentLine = remainingText[0];
      }
      
      // 创建行文本绘制器
      final TextPainter linePainter;
      if (isFirstLine && hasLargeFirstChar && currentLine.isNotEmpty) {
        linePainter = TextPainter(
          text: TextSpan(
            children: [
              TextSpan(
                text: currentLine[0],
                style: TextStyle(
                  fontSize: settings.fontSize * 1.5,
                  color: settings.textColor,
                  fontFamily: settings.fontFamily,
                ),
              ),
              if (currentLine.length > 1)
                TextSpan(
                  text: currentLine.substring(1),
                  style: TextStyle(
                    fontSize: settings.fontSize,
                    color: settings.textColor,
                    fontFamily: settings.fontFamily,
                  ),
                ),
            ],
          ),
          textDirection: TextDirection.ltr,
        );
      } else {
        linePainter = TextPainter(
          text: TextSpan(
            text: currentLine,
            style: TextStyle(
              fontSize: settings.fontSize,
              color: settings.textColor,
              fontFamily: settings.fontFamily,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
      }
      linePainter.layout();
      
      // 添加行信息
      lines.add(TextLine(
        text: currentLine,
        textPainter: linePainter,
        x: x,
        width: currentWidth,
        height: isFirstLine && hasLargeFirstChar 
            ? settings.fontSize * 1.5 * settings.lineHeight
            : settings.fontSize * settings.lineHeight,
      ));
      
      // 更新剩余文本
      remainingText = currentLine.length < remainingText.length 
          ? remainingText.substring(currentLine.length) 
          : '';
      
      isFirstLine = false;
    }
  }
}

class TextLine {
  final String text;
  final TextPainter textPainter;
  final double x;
  final double width;
  final double height;

  TextLine({
    required this.text,
    required this.textPainter,
    required this.x,
    required this.width,
    required this.height,
  });
} 