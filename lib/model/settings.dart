import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class Settings {
  static const String _currentPathKey = 'current_path';
  static const String _currentReadingTextFileKey = 'current_reading_text_file';
  static const String _readingProgressKey = 'reading_progress';
  static const String _textSettingsKey = 'text_settings';
  
  static Settings? _instance;
  late SharedPreferences _prefs;
  
  Settings._();
  
  static Settings get instance {
    _instance ??= Settings._();
    return _instance!;
  }

  // 初始化
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      Logger.instance.e('Failed to initialize Settings', e);
    }
  }

  // 获取当前路径
  String get currentPath {
    return _prefs.getString(_currentPathKey) ?? '/sdcard';
  }

  // 设置当前路径
  Future<void> setCurrentPath(String path) async {
    try {
      await _prefs.setString(_currentPathKey, path);
    } catch (e) {
      Logger.instance.e('Failed to save current path', e);
    }
  }

  // 修改：获取当前阅读的文本文件路径
  String? get currentReadingTextFile {
    return _prefs.getString(_currentReadingTextFileKey);
  }

  // 修改：设置当前阅读的文本文件路径
  Future<void> setCurrentReadingTextFile(String? filePath) async {
    try {
      if (filePath == null) {
        await _prefs.remove(_currentReadingTextFileKey);
      } else {
        await _prefs.setString(_currentReadingTextFileKey, filePath);
      }
      Logger.instance.d('Set current reading text file: $filePath');
    } catch (e) {
      Logger.instance.e('Failed to save current reading text file', e);
    }
  }

  // 清除所有设置
  Future<void> clear() async {
    try {
      await _prefs.clear();
    } catch (e) {
      Logger.instance.e('Failed to clear settings', e);
    }
  }

  // 获取阅读进度
  double getReadingProgress(String filePath) {
    final key = '${_readingProgressKey}_$filePath';
    return _prefs.getDouble(key) ?? 0.0;
  }

  // 保存阅读进度
  Future<void> saveReadingProgress(String filePath, double progress) async {
    try {
      final key = '${_readingProgressKey}_$filePath';
      await _prefs.setDouble(key, progress);
      Logger.instance.d('Saved reading progress for $filePath: $progress');
    } catch (e) {
      Logger.instance.e('Failed to save reading progress', e);
    }
  }

  // 清除特定文件的阅读进度
  Future<void> clearReadingProgress(String filePath) async {
    try {
      final key = '${_readingProgressKey}_$filePath';
      await _prefs.remove(key);
      Logger.instance.d('Cleared reading progress for $filePath');
    } catch (e) {
      Logger.instance.e('Failed to clear reading progress', e);
    }
  }

  // 保存文本设置
  Future<void> saveTextSettings(String filePath, Map<String, dynamic> settings) async {
    try {
      final key = '${_textSettingsKey}_$filePath';
      final jsonString = json.encode(settings);
      await _prefs.setString(key, jsonString);
      Logger.instance.d('Saved text settings for $filePath');
    } catch (e) {
      Logger.instance.e('Failed to save text settings', e);
    }
  }

  // 获取文本设置
  Map<String, dynamic>? getTextSettings(String filePath) {
    try {
      final key = '${_textSettingsKey}_$filePath';
      final jsonString = _prefs.getString(key);
      if (jsonString != null) {
        return json.decode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      Logger.instance.e('Failed to get text settings', e);
    }
    return null;
  }

  // 清除文本设置
  Future<void> clearTextSettings(String filePath) async {
    try {
      final key = '${_textSettingsKey}_$filePath';
      await _prefs.remove(key);
      Logger.instance.d('Cleared text settings for $filePath');
    } catch (e) {
      Logger.instance.e('Failed to clear text settings', e);
    }
  }
} 