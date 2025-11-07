import 'dart:io';
import 'package:record/record.dart';

/// Service for recording voice notes to m4a format.
///
/// Example:
/// ```dart
/// final recorder = VoiceRecorderService();
/// await recorder.startRecording();
/// final result = await recorder.stopRecording();
///
/// // Result:
/// // result.durationInMs, result.formattedDuration, result.filePath
/// ```
class VoiceRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  DateTime? _recordingStartTime;
  String? _recordingPath;

  bool get isRecording => _isRecording;

  int? get currentDurationInMs {
    if (!_isRecording || _recordingStartTime == null) return null;
    return DateTime.now().difference(_recordingStartTime!).inMilliseconds;
  }

  Future<bool> startRecording() async {
    if (_isRecording) return false;

    try {
      if (!await _recorder.hasPermission()) return false;

      final outputPath = _generateTempPath();
      final outputDir = File(outputPath).parent;
      if (!outputDir.existsSync()) {
        await outputDir.create(recursive: true);
      }

      await _recorder.start(
        path: outputPath,
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          numChannels: 1,
        ),
      );

      _recordingPath = outputPath;
      _recordingStartTime = DateTime.now();
      _isRecording = true;
      return true;
    } catch (e) {
      _isRecording = false;
      _recordingPath = null;
      _recordingStartTime = null;
      return false;
    }
  }

  Future<VoiceRecordingResult?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final duration = _recordingStartTime != null ? DateTime.now().difference(_recordingStartTime!).inMilliseconds : 0;

      await _recorder.stop();
      _isRecording = false;

      return VoiceRecordingResult(filePath: _recordingPath!, durationInMs: duration);
    } catch (e) {
      return null;
    } finally {
      _recordingPath = null;
      _recordingStartTime = null;
    }
  }

  Future<bool> cancelRecording() async {
    if (!_isRecording) return false;

    try {
      await _recorder.stop();
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (file.existsSync()) await file.delete();
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      _isRecording = false;
      _recordingPath = null;
      _recordingStartTime = null;
    }
  }

  void dispose() {
    if (_isRecording) cancelRecording();
    _recorder.dispose();
  }

  String _generateTempPath() {
    return '/tmp/storypad_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }
}

class VoiceRecordingResult {
  final String filePath;
  final int durationInMs;

  VoiceRecordingResult({
    required this.filePath,
    required this.durationInMs,
  });

  String get formattedDuration {
    final seconds = (durationInMs ~/ 1000) % 60;
    final minutes = (durationInMs ~/ (1000 * 60)) % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => 'VoiceRecordingResult(path: $filePath, duration: $formattedDuration)';
}
