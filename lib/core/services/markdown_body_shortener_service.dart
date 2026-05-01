import 'dart:math';
import 'package:storypad/core/extensions/string_extension.dart';

class MarkdownBodyShortenerService {
  static String call(String markdown, {int maxCharacterCount = 200}) {
    maxCharacterCount = max(maxCharacterCount, 50);
    String body = markdown.trim();

    if (body.split("\n").length > 10) body = "${body.split("\n").getRange(0, 10).join("\n")}...";
    if (body.length <= maxCharacterCount) return body.sanitizeUtf16;

    String extract = body.substring(0, _linkAwareEndIndex(body, maxCharacterCount));
    var result = trimBody(extract);

    return result.sanitizeUtf16;
  }

  static int _linkAwareEndIndex(String body, int maxCharacterCount) {
    for (final pattern in [
      RegExp(r'\[[^\]\n]*\]\([^\)\n]*\)'),
      RegExp(r'https?:\/\/[^\s<>\]]+'),
    ]) {
      for (final match in pattern.allMatches(body)) {
        if (match.start < maxCharacterCount && match.end > maxCharacterCount) {
          return match.end;
        }
      }
    }

    return maxCharacterCount;
  }

  static String trimBody(String body) {
    body = body.trim();

    int bodyLength = body.length;
    int santitizedBodyLength = body.length;

    List<String> endWiths = [
      '-',
      "- [",
      "- [x",
      "- [ ]",
      "- [x]",
      ...List.generate(9, (index) => "$index."),
    ];

    for (String ew in endWiths) {
      if (body.endsWith(ew)) {
        santitizedBodyLength = bodyLength - ew.length;
      }
    }

    return bodyLength >= santitizedBodyLength ? "${body.substring(0, santitizedBodyLength).trim()}..." : body;
  }
}
