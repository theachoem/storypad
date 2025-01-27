import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';

class QuillService {
  static bool isImageBase64(String imageUrl) {
    if (imageUrl.startsWith('http')) return false;
    return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageUrl);
  }

  static String toPlainText(Root root) {
    String plainText = root.children.map((Node e) {
      final atts = e.style.attributes;
      Attribute? att = atts['list'] ?? atts['blockquote'] ?? atts['code-block'] ?? atts['header'];

      if (e is Block) {
        int index = 0;
        String result = "";

        if (att?.key == "code-block") {
          result += "```\n";
        }

        for (Node entry in e.children) {
          if (att?.key == "blockquote") {
            String text = entry.toPlainText();
            text = text.replaceFirst(RegExp('\n'), '', text.length - 1);
            result += "\n> $text";
          } else if (att?.key == "code-block") {
            result += entry.toPlainText();
          } else {
            if (att?.value == "checked") {
              result += '- [x] ${entry.toPlainText()}';
            } else if (att?.value == "unchecked") {
              result += "- [ ] ${entry.toPlainText()}";
            } else if (att?.value == "ordered") {
              index++;
              result += "$index. ${entry.toPlainText()}";
            } else if (att?.value == "bullet") {
              result += "- ${entry.toPlainText()}";
            }
          }
        }

        if (att?.key == "code-block") {
          result += "```";
        }

        return result;
      } else if (e is Line && att != null) {
        String prefix = "#" * ((att.value as int) + 3);
        return "$prefix ${e.toPlainText()}";
      } else {
        return e.toPlainText();
      }
    }).join();

    // replace all image object to empty
    plainText = plainText.replaceAll("\uFFFC", "");
    return plainText;
  }

  static bool urlOrExistFile(String imageUrl) =>
      isImageBase64(imageUrl) || imageUrl.startsWith('http') || File(imageUrl).existsSync();

  static List<String> imagesFromContent(StoryContentDbModel? content) {
    List<String> images = [];

    try {
      for (dynamic e in content?.pages?.expand((e) => e) ?? []) {
        final insert = e['insert'];
        if (insert is Map) {
          for (MapEntry<dynamic, dynamic> e in insert.entries) {
            if (e.value != null && e.value.isNotEmpty) {
              String imageUrl = e.value;
              if (urlOrExistFile(imageUrl)) {
                images.add(e.value);
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) rethrow;
    }

    return images;
  }
}
