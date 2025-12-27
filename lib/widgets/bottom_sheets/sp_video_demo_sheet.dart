import 'dart:io';

import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/services/firestore_storage_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:video_player/video_player.dart';

class SpVideoDemoSheet extends BaseBottomSheet {
  const SpVideoDemoSheet({
    required this.videoFile,
    required this.demoTitle,
    required this.demoSubtitle,
  });

  final String demoTitle;
  final String demoSubtitle;
  final File videoFile;

  static Future<T?> showVideoSheet<T>({
    required BuildContext context,
    required String videoUrlPath,
    required String demoTitle,
    required String demoSubtitle,
  }) async {
    File? file;

    try {
      file = await FirestoreStorageService.instance.getCachedFile(videoUrlPath);
      file ??= !context.mounted
          ? null
          : await MessengerService.of(context).showLoading(
              debugSource: 'SpVideoDemoSheet.showVideoSheet',
              future: () => FirestoreStorageService.instance.downloadFile(videoUrlPath).then((e) => e.file),
            );
    } catch (e) {
      return null;
    }

    if (!context.mounted) return null;
    if (file == null) return null;

    return SpVideoDemoSheet(
      videoFile: file,
      demoTitle: demoTitle,
      demoSubtitle: demoSubtitle,
    ).show<T>(context: context);
  }

  @override
  Widget build(BuildContext context, double bottomPadding) => _SpVideoDemoSheet(params: this);

  @override
  double get cupertinoPaddingTop => 0.0;

  @override
  bool get showMaterialDragHandle => false;

  @override
  bool get fullScreen => false;
}

class _SpVideoDemoSheet extends StatefulWidget {
  const _SpVideoDemoSheet({
    required this.params,
  });

  final SpVideoDemoSheet params;

  @override
  State<_SpVideoDemoSheet> createState() => __SpVideoDemoSheetState();
}

class __SpVideoDemoSheetState extends State<_SpVideoDemoSheet> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.params.videoFile)
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            mainAxisSize: .min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                decoration: BoxDecoration(
                  color: ColorScheme.of(context).primary,
                ),
                child: Wrap(
                  clipBehavior: .hardEdge,
                  alignment: .center,
                  runAlignment: .center,
                  children: [
                    if (_controller.value.isInitialized)
                      SizedBox(
                        width: 270,
                        child: ClipRRect(
                          clipBehavior: .hardEdge,
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 24.0),
              Text(
                widget.params.demoTitle,
                style: TextTheme.of(context).titleLarge,
              ),
              const SizedBox(height: 8.0),
              Text(
                widget.params.demoSubtitle,
                style: TextTheme.of(context).bodyMedium,
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom + 16.0),
            ],
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: CloseButton(
            style: IconButton.styleFrom(
              backgroundColor: ColorScheme.of(context).readOnly.surface3,
            ),
          ),
        ),
      ],
    );
  }
}
