import 'package:flutter/material.dart';

class TextSettings {
  double fontSize;
  Color textColor;
  int paragraphIndent;
  bool enlargeFirstLetter;
  bool isBold;
  double lineHeight;
  double paragraphSpacing;
  bool hasUnderline;

  TextSettings({
    this.fontSize = 16,
    this.textColor = Colors.white,
    this.paragraphIndent = 0,
    this.enlargeFirstLetter = false,
    this.isBold = false,
    this.lineHeight = 1.5,
    this.paragraphSpacing = 1.0,
    this.hasUnderline = false,
  });

  // 从 JSON 创建实例
  factory TextSettings.fromJson(Map<String, dynamic> json) {
    return TextSettings(
      fontSize: json['fontSize']?.toDouble() ?? 16,
      textColor: Color(json['textColor'] ?? 0xFFFFFFFF),
      paragraphIndent: json['paragraphIndent'] ?? 0,
      enlargeFirstLetter: json['enlargeFirstLetter'] ?? false,
      isBold: json['isBold'] ?? false,
      lineHeight: json['lineHeight']?.toDouble() ?? 1.5,
      paragraphSpacing: json['paragraphSpacing']?.toDouble() ?? 1.0,
      hasUnderline: json['hasUnderline'] ?? false,
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'textColor': textColor.value,
      'paragraphIndent': paragraphIndent,
      'enlargeFirstLetter': enlargeFirstLetter,
      'isBold': isBold,
      'lineHeight': lineHeight,
      'paragraphSpacing': paragraphSpacing,
      'hasUnderline': hasUnderline,
    };
  }

  TextSettings copyWith({
    double? fontSize,
    Color? textColor,
    int? paragraphIndent,
    bool? enlargeFirstLetter,
    bool? isBold,
    double? lineHeight,
    double? paragraphSpacing,
    bool? hasUnderline,
  }) {
    return TextSettings(
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      paragraphIndent: paragraphIndent ?? this.paragraphIndent,
      enlargeFirstLetter: enlargeFirstLetter ?? this.enlargeFirstLetter,
      isBold: isBold ?? this.isBold,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      hasUnderline: hasUnderline ?? this.hasUnderline,
    );
  }
}

class TextSettingsDialog extends StatefulWidget {
  final TextSettings initialSettings;
  final Function(TextSettings) onSettingsChanged;

  const TextSettingsDialog({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
  });

  @override
  State<TextSettingsDialog> createState() => _TextSettingsDialogState();
}

class _TextSettingsDialogState extends State<TextSettingsDialog> {
  late TextSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('文本设置', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.black87,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 字体大小
            Row(
              children: [
                const Text('字体大小', style: TextStyle(color: Colors.white)),
                Expanded(
                  child: Slider(
                    value: _settings.fontSize,
                    min: 12,
                    max: 32,
                    divisions: 20,
                    label: _settings.fontSize.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(fontSize: value);
                        widget.onSettingsChanged(_settings);
                      });
                    },
                  ),
                ),
              ],
            ),

            // 字体颜色
            Row(
              children: [
                const Text('字体颜色', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    // 显示简单的颜色选择器
                    showDialog(
                      context: context,
                      builder: (context) => SimpleColorPicker(
                        currentColor: _settings.textColor,
                        onColorSelected: (color) {
                          setState(() {
                            _settings = _settings.copyWith(textColor: color);
                            widget.onSettingsChanged(_settings);
                          });
                        },
                      ),
                    );
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _settings.textColor,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),

            // 段前空格数
            Row(
              children: [
                const Text('段前空格', style: TextStyle(color: Colors.white)),
                Expanded(
                  child: Slider(
                    value: _settings.paragraphIndent.toDouble(),
                    min: 0,
                    max: 8,
                    divisions: 8,
                    label: _settings.paragraphIndent.toString(),
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(
                            paragraphIndent: value.round());
                        widget.onSettingsChanged(_settings);
                      });
                    },
                  ),
                ),
              ],
            ),

            // 段落首字符加大
            SwitchListTile(
              title: const Text('段落首字符加大',
                  style: TextStyle(color: Colors.white)),
              value: _settings.enlargeFirstLetter,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(enlargeFirstLetter: value);
                  widget.onSettingsChanged(_settings);
                });
              },
            ),

            // 文本加粗
            SwitchListTile(
              title: const Text('文本加粗', style: TextStyle(color: Colors.white)),
              value: _settings.isBold,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(isBold: value);
                  widget.onSettingsChanged(_settings);
                });
              },
            ),

            // 行间距
            Row(
              children: [
                const Text('行间距', style: TextStyle(color: Colors.white)),
                Expanded(
                  child: Slider(
                    value: _settings.lineHeight,
                    min: 1.0,
                    max: 3.0,
                    divisions: 20,
                    label: _settings.lineHeight.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(lineHeight: value);
                        widget.onSettingsChanged(_settings);
                      });
                    },
                  ),
                ),
              ],
            ),

            // 段间距
            Row(
              children: [
                const Text('段间距', style: TextStyle(color: Colors.white)),
                Expanded(
                  child: Slider(
                    value: _settings.paragraphSpacing,
                    min: 1.0,
                    max: 3.0,
                    divisions: 20,
                    label: _settings.paragraphSpacing.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(paragraphSpacing: value);
                        widget.onSettingsChanged(_settings);
                      });
                    },
                  ),
                ),
              ],
            ),

            // 文本下划线
            SwitchListTile(
              title: const Text('文本下划线',
                  style: TextStyle(color: Colors.white)),
              value: _settings.hasUnderline,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(hasUnderline: value);
                  widget.onSettingsChanged(_settings);
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// 简单的颜色选择器
class SimpleColorPicker extends StatelessWidget {
  final Color currentColor;
  final Function(Color) onColorSelected;

  const SimpleColorPicker({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.white,
      Colors.grey[300]!,
      Colors.grey[500]!,
      Colors.yellow[100]!,
      Colors.green[100]!,
    ];

    return AlertDialog(
      title: const Text('选择颜色', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.black87,
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: colors.map((color) {
          return GestureDetector(
            onTap: () {
              onColorSelected(color);
              Navigator.of(context).pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}