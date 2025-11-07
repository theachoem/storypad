import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/duration_format_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/services/voice_recorder_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_audio_player.dart';
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

        final audioEmbed = BlockEmbed('audio', savedAsset.embedLink);

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
  VoiceRecordingResult? recordingResult;

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
        setState(() {
          recording = false;
          recordingResult = result;
        });
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
    final hasRecording = recordingResult != null;

    return Stack(
      children: [
        Container(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: widget.bottomPadding + 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              hasRecording ? buildPlaybackUI(context) : buildRecordingUI(context),
            ],
          ),
        ),
        if (kIsCupertino && !hasRecording)
          Positioned(
            right: 8,
            top: 0,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: recording ? cancelRecording : () => Navigator.of(context).pop(),
              child: const Icon(CupertinoIcons.xmark),
            ),
          ),
      ],
    );
  }

  Widget buildRecordingUI(BuildContext context) {
    return Column(
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
        buildRecordingStatus(context),
        const SizedBox(height: 24.0),
        SizedBox(
          width: double.infinity,
          child: buildRecordingAction(context),
        ),
      ],
    );
  }

  Widget buildPlaybackUI(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (recordingResult != null) SpAudioPlayer(filePath: recordingResult!.filePath),
        const SizedBox(height: 32.0),
        buildPlaybackActions(context),
      ],
    );
  }

  Widget buildPlaybackActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: kIsCupertino
                ? CupertinoButton(
                    child: Text(tr('button.delete')),
                    onPressed: () {
                      setState(() {
                        recordingResult = null;
                      });
                    },
                  )
                : OutlinedButton.icon(
                    icon: const Icon(SpIcons.delete),
                    onPressed: () {
                      setState(() {
                        recordingResult = null;
                      });
                    },
                    label: Text(tr('button.delete')),
                  ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: kIsCupertino
                ? CupertinoButton.filled(
                    onPressed: recordingResult != null ? () => Navigator.of(context).pop(recordingResult) : null,
                    child: Text(tr('button.done')),
                  )
                : FilledButton.icon(
                    icon: const Icon(SpIcons.save),
                    onPressed: recordingResult != null ? () => Navigator.of(context).pop(recordingResult) : null,
                    label: Text(tr('button.done')),
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildRecordingStatus(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: Durations.medium1,
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: !recording ? Colors.transparent : Theme.of(context).colorScheme.error,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8.0),
        Text(
          recording ? tr('general.recording') : '',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget buildRecordingAction(BuildContext context) {
    if (kIsCupertino) {
      return CupertinoButton.filled(
        onPressed: recording ? stopRecording : startRecording,
        child: Text(recording ? tr('button.stop') : tr('button.record_voice')),
      );
    } else {
      return FilledButton.icon(
        onPressed: recording ? stopRecording : startRecording,
        icon: recording ? null : const Icon(SpIcons.voice),
        label: Text(recording ? tr('button.stop') : tr('button.record_voice')),
      );
    }
  }
}
