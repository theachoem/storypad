import 'dart:io';
import 'package:flutter/material.dart';
import 'package:storypad/core/services/firestore_storage_service.dart';

class SpFirestoreStorageDownloaderBuilder extends StatefulWidget {
  const SpFirestoreStorageDownloaderBuilder({
    super.key,
    required this.filePath,
    required this.builder,
  });

  final String filePath;
  final Widget Function(BuildContext context, File? file, bool failed) builder;

  @override
  State<SpFirestoreStorageDownloaderBuilder> createState() => _SpFirestoreStorageDownloaderBuilderState();
}

class _SpFirestoreStorageDownloaderBuilderState extends State<SpFirestoreStorageDownloaderBuilder> {
  File? file;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await FirestoreStorageService.instance.queueDownloadFile(widget.filePath);
      file = result.file;
      setState(() {});
    } catch (e) {
      failed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, file, failed);
  }
}
