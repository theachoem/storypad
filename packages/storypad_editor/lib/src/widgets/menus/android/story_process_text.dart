import 'package:flutter/services.dart';

/// The Android apps that act on selected text ("Process Text": Translate, Ask …), from the package's Android side
/// (`StorypadEditorPlugin.java`), which queries them as a native TextView does: afresh each time, in the system's
/// order, only those the app may start, labelled as the system labels them. Flutter's [DefaultProcessTextService]
/// queries once per engine and keeps the results -- an app updated since then shows its activity's class name -- and
/// returns them unordered.
abstract final class StoryProcessText {
  static const MethodChannel _channel = MethodChannel('storypad_editor/process_text');

  /// The actions, in the system's order; none without the Android side (e.g. in tests).
  static Future<List<ProcessTextAction>> queryTextActions() async {
    try {
      final actions = await _channel.invokeListMethod<Map<Object?, Object?>>('queryTextActions');
      return [
        for (final action in actions ?? const <Map<Object?, Object?>>[])
          ProcessTextAction(action['id']! as String, action['label']! as String),
      ];
    } on MissingPluginException {
      return const [];
    }
  }

  /// Gives [text] to [id]'s app (allowed to change it unless [readOnly]); the text it returns, if any.
  static Future<String?> processTextAction(String id, String text, bool readOnly) async {
    try {
      return await _channel.invokeMethod<String>('processTextAction', {'id': id, 'text': text, 'readOnly': readOnly});
    } on PlatformException {
      return null;
    }
  }
}
