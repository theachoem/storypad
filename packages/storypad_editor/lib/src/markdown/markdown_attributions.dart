import 'package:super_editor/super_editor.dart';

import 'markdown_link_destination.dart';

/// The formatting attributions Markdown can represent, and comparing texts by them.
class MarkdownAttributions {
  const MarkdownAttributions._();

  /// Whether Markdown can represent [attribution].
  static bool isSupported(Attribution attribution) =>
      attribution == boldAttribution ||
      attribution == italicsAttribution ||
      attribution == strikethroughAttribution ||
      attribution == underlineAttribution ||
      attribution == codeAttribution ||
      attribution is LinkAttribution ||
      attribution is ColorAttribution ||
      attribution is BackgroundColorAttribution ||
      attribution is ScriptAttribution;

  /// The supported attributions at [offset].
  static Set<Attribution> at(AttributedText text, int offset) =>
      text.getAllAttributionsAt(offset).where(isSupported).toSet();

  /// Whether two texts are equal as far as Markdown can tell: same characters, and the same supported attributions on
  /// every character except line breaks (which carry no formatting in Markdown).
  static bool textEquals(AttributedText a, AttributedText b) {
    final plainText = a.toPlainText();
    if (plainText != b.toPlainText()) return false;

    for (var i = 0; i < plainText.length; i++) {
      if (plainText[i] == '\n') continue;
      final attributionsA = at(a, i).map(_canonical).toSet();
      final attributionsB = at(b, i).map(_canonical).toSet();
      if (attributionsA.length != attributionsB.length || !attributionsA.containsAll(attributionsB)) return false;
    }
    return true;
  }

  /// Link destinations are compared the way Markdown normalizes them.
  static Attribution _canonical(Attribution attribution) => attribution is LinkAttribution
      ? LinkAttribution(MarkdownLinkDestination.canonical(attribution.plainTextUri))
      : attribution;
}
