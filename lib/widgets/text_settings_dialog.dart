import 'package:flutter/material.dart';
import '../models/text_settings.dart';  // 导入 TextSettings

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

            // 段落首行空格
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('首行空格', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,  // 确保占满宽度
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(value: 0, label: Text('0')),
                      ButtonSegment<int>(value: 1, label: Text('1')),
                      ButtonSegment<int>(value: 2, label: Text('2')),
                      ButtonSegment<int>(value: 4, label: Text('4')),
                    ],
                    selected: {_settings.firstLineSpaces},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        _settings = _settings.copyWith(
                          firstLineSpaces: newSelection.first,
                        );
                        widget.onSettingsChanged(_settings);
                      });
                    },
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      backgroundColor: MaterialStateProperty.all(Colors.grey[800]),
                      // 调整内边距使按钮更紧凑
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            const SizedBox(height: 16),

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

            // 段落间距
            Row(
              children: [
                const Text('段落间距', style: TextStyle(color: Colors.white)),
                Expanded(
                  child: Slider(
                    value: _settings.paragraphSpacing,
                    min: 0.0,
                    max: 5.0,
                    divisions: 50,
                    label: _settings.paragraphSpacing.toString(),
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

            // 允许编辑
            SwitchListTile(
              title: const Text('允许编辑',
                  style: TextStyle(color: Colors.white)),
              value: _settings.allowEditing,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(allowEditing: value);
                  widget.onSettingsChanged(_settings);
                });
              },
            ),

            // 字体选择
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('字体', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('系统'),
                      selected: _settings.fontFamily == null,
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _settings = _settings.copyWith(fontFamily: null);
                            widget.onSettingsChanged(_settings);
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text('宋体', style: TextStyle(fontFamily: 'SongTi')),
                      selected: _settings.fontFamily == 'SongTi',
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _settings = _settings.copyWith(fontFamily: 'SongTi');
                            widget.onSettingsChanged(_settings);
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text('幼圆', style: TextStyle(fontFamily: 'YouYuan')),
                      selected: _settings.fontFamily == 'YouYuan',
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _settings = _settings.copyWith(fontFamily: 'YouYuan');
                            widget.onSettingsChanged(_settings);
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text('方正小黑', style: TextStyle(fontFamily: 'FZXiaoHei')),
                      selected: _settings.fontFamily == 'FZXiaoHei',
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _settings = _settings.copyWith(fontFamily: 'FZXiaoHei');
                            widget.onSettingsChanged(_settings);
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: Text('楷书', style: TextStyle(fontFamily: 'KaiShu')),
                      selected: _settings.fontFamily == 'KaiShu',
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _settings = _settings.copyWith(fontFamily: 'KaiShu');
                            widget.onSettingsChanged(_settings);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
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
      title: const Text('���择颜色', style: TextStyle(color: Colors.white)),
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