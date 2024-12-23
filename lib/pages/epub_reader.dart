import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'dart:io';

class EpubReader extends StatefulWidget {
  final String epubPath;

  EpubReader({required this.epubPath});

  @override
  _EpubReaderState createState() => _EpubReaderState();
}

class _EpubReaderState extends State<EpubReader> {
  String? content;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadEpub();
  }

  Future<void> loadEpub() async {
    try {
      // 读取 EPUB 文件
      final bytes = File(widget.epubPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 查找 HTML 文件
      for (final file in archive) {
        if (file.name.endsWith('.html') || file.name.endsWith('.xhtml')) {
          content = String.fromCharCodes(file.content);
          break;
        }
      }
    } catch (e) {
      print('Error loading EPUB: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EPUB Reader'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Html(data: content ?? 'No content found'),
            ),
    );
  }
}
