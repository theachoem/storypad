import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SpCacheFileDownloaderBuilder extends StatefulWidget {
  const SpCacheFileDownloaderBuilder({
    super.key,
    required this.fileUrl,
    required this.builder,
  });

  final String fileUrl;
  final Widget Function(BuildContext context, File? file, bool failed) builder;

  @override
  State<SpCacheFileDownloaderBuilder> createState() => _SpCacheFileDownloaderBuilderState();
}

class _SpCacheFileDownloaderBuilderState extends State<SpCacheFileDownloaderBuilder> {
  File? file;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      file = await CachedNetworkImageProvider.defaultCacheManager.getSingleFile(widget.fileUrl);
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
