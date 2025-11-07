import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/duration_format_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/services/voice_recorder_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

/// Sheet for recording voice notes
///
/// Usage:
/// ```dart
/// final result = await SpVoiceRecordingSheet().show(context);
///
/// if (result != null) {
///   // Use result.filePath and result.durationInMs
/// }
/// ```
class SpVoiceRecordingSheet extends BaseBottomSheet {
  const SpVoiceRecordingSheet();

  @override
  bool get fullScreen => false;

  @override
  bool get showMaterialDragHandle => true;

  static Future<void> showQuillRecorder({
    required BuildContext context,
    required QuillController controller,
  }) async {
    final result = await const SpVoiceRecordingSheet().show(context: context);

    if (result is VoiceRecordingResult && context.mounted) {
      final asset = AssetDbModel.fromLocalPath(
        id: DateTime.now().millisecondsSinceEpoch,
        localPath: result.filePath,
        type: AssetType.audio,
        durationInMs: result.durationInMs,
      );

      final savedAsset = await asset.save();
      if (savedAsset != null && context.mounted) {
        final index = controller.selection.baseOffset;
        final length = controller.selection.extentOffset - index;

        final audioEmbed = BlockEmbed('audio', savedAsset.link);

        controller.replaceText(index, length, audioEmbed, null);
        controller.moveCursorToPosition(index + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return _VoiceRecordingContent(bottomPadding: bottomPadding);
  }
}

class _VoiceRecordingContent extends StatefulWidget {
  const _VoiceRecordingContent({
    required this.bottomPadding,
  });

  final double bottomPadding;

  @override
  State<_VoiceRecordingContent> createState() => _VoiceRecordingContentState();
}

class _VoiceRecordingContentState extends State<_VoiceRecordingContent> {
  late VoiceRecorderService recorder;

  bool recording = false;
  int durationInMs = 0;

  @override
  void initState() {
    super.initState();

    recorder = VoiceRecorderService();
  }

  @override
  void dispose() {
    recorder.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      final success = await recorder.startRecording();

      if (success && mounted) {
        setState(() {
          recording = true;
          durationInMs = 0;
        });

        while (recording && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            setState(() => durationInMs = recorder.currentDurationInMs ?? 0);
          }
        }
      }
    } catch (e) {
      if (mounted) MessengerService.of(context).showSnackBar(e.toString(), success: false);
    }
  }

  Future<void> stopRecording() async {
    try {
      final result = await recorder.stopRecording();

      if (mounted) {
        setState(() => recording = false);
        if (result != null) Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) MessengerService.of(context).showSnackBar(e.toString(), success: false);
    }
  }

  Future<void> cancelRecording() async {
    await recorder.cancelRecording();
    if (mounted) {
      setState(() => recording = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 24.0,
        bottom: widget.bottomPadding + 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DurationFormatService.formatMs(durationInMs),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12.0),
          if (recording) buildRecordingStatus(context),
          const SizedBox(height: 24.0),
          buildActions(context),
        ],
      ),
    );
  }

  Widget buildRecordingStatus(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8.0),
        Text(
          tr('general.recording'),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: recording ? cancelRecording : () => Navigator.of(context).pop(),
            child: Text(recording ? tr('button.discard') : tr('button.cancel')),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: FilledButton.icon(
            onPressed: recording ? stopRecording : startRecording,
            icon: Icon(
              recording ? SpIcons.pauseCircle : SpIcons.voice,
            ),
            label: Text(recording ? tr('button.stop') : tr('button.record_voice')),
          ),
        ),
      ],
    );
  }
}
