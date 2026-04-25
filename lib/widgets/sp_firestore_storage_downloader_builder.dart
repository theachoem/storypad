import 'dart:io';
import 'package:flutter/material.dart';
import 'package:storypad/core/services/cloud_storage/cloud_storage_service.dart';

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

    file = CloudStorageService.instance.getCachedFile(widget.filePath);
    if (file == null) downloadAndLoadFile();
  }

  Future<void> downloadAndLoadFile() async {
    try {
      file = await CloudStorageService.instance.downloadFile(widget.filePath).then((e) => e.file);
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
