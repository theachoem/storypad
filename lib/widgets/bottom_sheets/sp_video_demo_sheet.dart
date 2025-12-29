import 'dart:io';

import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/services/firestore_storage_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:video_player/video_player.dart';

class SpVideoDemoSheet extends BaseBottomSheet {
  const SpVideoDemoSheet({
    required this.demoTitle,
    required this.demoSubtitle,
    required this.demoBackgroundColor,
    required this.controller,
  });

  final String demoTitle;
  final String demoSubtitle;
  final Color? demoBackgroundColor;
  final VideoPlayerController controller;

  static Future<T?> showVideoSheet<T>({
    required BuildContext context,
    required String videoUrlPath,
    required String demoTitle,
    required String demoSubtitle,
    required Color? demoBackgroundColor,
    required double demoWidth,
    required double demoAspectRatio,
  }) async {
    File? file;
    VideoPlayerController? controller;

    try {
      file = FirestoreStorageService.instance.getCachedFile(videoUrlPath);
      file ??= !context.mounted
          ? null
          : await MessengerService.of(context).showLoading(
              debugSource: 'SpVideoDemoSheet.showVideoSheet',
              future: () => FirestoreStorageService.instance.downloadFile(videoUrlPath).then((e) => e.file),
            );

      if (file == null) return null;

      controller = VideoPlayerController.file(file);
      await controller.initialize();

      if (!controller.value.isInitialized) return null;
    } catch (e) {
      return null;
    }

    if (!context.mounted) return null;

    return SpVideoDemoSheet(
      controller: controller,
      demoTitle: demoTitle,
      demoSubtitle: demoSubtitle,
      demoBackgroundColor: demoBackgroundColor,
    ).show(context: context, useRootNavigator: true);
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
  State<_SpVideoDemoSheet> createState() => _SpVideoDemoSheetState();
}

class _SpVideoDemoSheetState extends State<_SpVideoDemoSheet> {
  @override
  void initState() {
    super.initState();

    _load();
  }

  void _load() async {
    await widget.params.controller.setLooping(true);
    await widget.params.controller.play();
  }

  @override
  void dispose() {
    widget.params.controller.dispose();
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
                decoration: BoxDecoration(color: widget.params.demoBackgroundColor),
                child: Wrap(
                  clipBehavior: .hardEdge,
                  alignment: .center,
                  runAlignment: .center,
                  children: [
                    SizedBox(
                      width: 270,
                      child: ClipRRect(
                        clipBehavior: .hardEdge,
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: widget.params.controller.value.aspectRatio,
                          child: VideoPlayer(widget.params.controller),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 24.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  widget.params.demoTitle,
                  style: TextTheme.of(context).titleLarge,
                ),
              ),
              const SizedBox(height: 8.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  widget.params.demoSubtitle,
                  style: TextTheme.of(context).bodyMedium,
                  textAlign: .center,
                ),
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom + 24.0),
            ],
          ),
        ),
        Positioned(
          // When width < height, in most cases this sheet in shown half screen.
          // In that case, no need to add status bar height to the top padding.
          top: MediaQuery.sizeOf(context).width < MediaQuery.sizeOf(context).height
              ? 12.0
              : MediaQuery.paddingOf(context).top + 12.0,
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
