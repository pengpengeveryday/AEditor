import 'package:flutter/material.dart';

class TextSettings {
  double fontSize;
  Color textColor;
  int paragraphIndent;
  int firstLineSpaces;
  bool enlargeFirstLetter;
  bool isBold;
  double lineHeight;
  double paragraphSpacing;
  bool hasUnderline;
  String? fontFamily;
  final bool allowEditing;

  TextSettings({
    this.fontSize = 16,
    this.textColor = Colors.white,
    this.paragraphIndent = 0,
    this.firstLineSpaces = 0,
    this.enlargeFirstLetter = false,
    this.isBold = false,
    this.lineHeight = 1.5,
    this.paragraphSpacing = 1.0,
    this.hasUnderline = false,
    this.fontFamily,
    this.allowEditing = true,
  });

  factory TextSettings.fromJson(Map<String, dynamic> json) {
    return TextSettings(
      fontSize: json['fontSize']?.toDouble() ?? 16,
      textColor: Color(json['textColor'] ?? 0xFFFFFFFF),
      paragraphIndent: json['paragraphIndent'] ?? 0,
      firstLineSpaces: json['firstLineSpaces'] ?? 0,
      enlargeFirstLetter: json['enlargeFirstLetter'] ?? false,
      isBold: json['isBold'] ?? false,
      lineHeight: json['lineHeight']?.toDouble() ?? 1.5,
      paragraphSpacing: json['paragraphSpacing']?.toDouble() ?? 1.0,
      hasUnderline: json['hasUnderline'] ?? false,
      fontFamily: json['fontFamily'],
      allowEditing: json['allowEditing'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'textColor': textColor.value,
      'paragraphIndent': paragraphIndent,
      'firstLineSpaces': firstLineSpaces,
      'enlargeFirstLetter': enlargeFirstLetter,
      'isBold': isBold,
      'lineHeight': lineHeight,
      'paragraphSpacing': paragraphSpacing,
      'hasUnderline': hasUnderline,
      'fontFamily': fontFamily,
      'allowEditing': allowEditing,
    };
  }

  TextSettings copyWith({
    double? fontSize,
    Color? textColor,
    int? paragraphIndent,
    int? firstLineSpaces,
    bool? enlargeFirstLetter,
    bool? isBold,
    double? lineHeight,
    double? paragraphSpacing,
    bool? hasUnderline,
    String? fontFamily,
    bool? allowEditing,
  }) {
    return TextSettings(
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      paragraphIndent: paragraphIndent ?? this.paragraphIndent,
      firstLineSpaces: firstLineSpaces ?? this.firstLineSpaces,
      enlargeFirstLetter: enlargeFirstLetter ?? this.enlargeFirstLetter,
      isBold: isBold ?? this.isBold,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      hasUnderline: hasUnderline ?? this.hasUnderline,
      fontFamily: fontFamily ?? this.fontFamily,
      allowEditing: allowEditing ?? this.allowEditing,
    );
  }
} 