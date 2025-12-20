import 'package:storypad/core/types/asset_type.dart';

/// Converts Quill Delta JSON format to plain text or markdown.
///
/// Example Delta JSON:
/// ```json
/// [
///   {"insert": "Hello "},
///   {"insert": "World", "attributes": {"bold": true}},
///   {"insert": "\n"}
/// ]
/// ```
///
/// Output with markdown=true: "Hello **World**\n"
/// Output with markdown=false: "Hello World\n"
class QuillDeltaToPlainTextService {
  /// Extracts and formats text from Delta operations.
  ///
  /// Delta operations structure:
  /// - Each op has an "insert" field (String or Map for embeds)
  /// - Line-level attributes (list, blockquote, code-block, indent) are on the newline character
  /// - Text-level attributes (bold, italic, link) are on text segments
  ///
  /// Example Delta ops:
  /// ```json
  /// [
  ///   {"insert": "First item"},
  ///   {"insert": "\n", "attributes": {"list": "bullet"}},
  ///   {"insert": "Second item"},
  ///   {"insert": "\n", "attributes": {"list": "bullet"}}
  /// ]
  /// ```
  /// Output: "- First item\n- Second item\n"
  static String call(
    List<dynamic> deltaOps, {
    bool markdown = true,
    bool includeMarkdownEmbeds = false,

    // eg. ../
    String embedRelativePath = '',
  }) {
    // orderedListCounter: Tracks the numbering for ordered lists at each indent level
    // Example: {0: 3, 1: 2} means:
    //   - Level 0 (no indent): next number is 4 (1. 2. 3. [4])
    //   - Level 1 (one indent): next number is 3 (a. b. [c])
    Map<int, int>? orderedListCounter = {};

    // buffer: Accumulates the final output text (line by line)
    // Example after processing: "# Title\n- Item 1\n- Item 2\n"
    final StringBuffer buffer = StringBuffer();

    // currentLineText: Temporarily stores text for the current line being processed
    // Gets flushed to buffer when we hit a newline character
    // Example: "Hello **World**" (before adding "\n" to buffer)
    String currentLineText = '';

    // inCodeBlock: Tracks whether we're currently inside a code block
    // Helps determine when to add opening/closing ``` markers
    // Example: false → true (add ```), true → false (add ```\n)
    bool inCodeBlock = false;

    for (final op in deltaOps) {
      if (op is! Map<String, dynamic>) continue;

      final insert = op['insert'];
      final attributes = (op['attributes'] as Map<String, dynamic>?) ?? {};

      if (insert is String) {
        // Process text inserts - split by newlines since line attributes are on '\n'
        if (insert.contains('\n')) {
          final parts = insert.split('\n');

          for (int i = 0; i < parts.length; i++) {
            if (parts[i].isNotEmpty) {
              final formattedText = _applyTextFormatting(parts[i], attributes, markdown);
              currentLineText += formattedText;
            }

            // When we encounter a newline, flush the current line with its formatting
            if (i < parts.length - 1) {
              // Extract line-level attributes from the newline's attributes
              // Example: {"insert": "\n", "attributes": {"list": "bullet", "indent": 1}}
              final indentLevel = attributes['indent'] as int?;
              final indent = '\t' * (indentLevel ?? 0);
              final list = attributes['list'] as String?; // 'bullet', 'ordered', 'checked', 'unchecked'
              final isBlockquote = attributes.containsKey('blockquote');
              final isCodeBlock = attributes.containsKey('code-block');

              // Handle code block transitions
              if (inCodeBlock && !isCodeBlock) {
                buffer.write('```\n');
                inCodeBlock = false;
              }

              String linePrefix = indent;

              if (isCodeBlock) {
                // Code blocks: wrap in ``` markers
                // Example: ```\ncode here\n```\n
                if (!inCodeBlock) {
                  linePrefix = '```\n';
                  inCodeBlock = true;
                }
              } else if (isBlockquote) {
                // Blockquotes: prefix with '>' (multiple '>' for nested quotes)
                // Example: "> quoted text\n" or "> > nested quote\n"
                linePrefix = indentLevel != null ? '> ' * (indentLevel + 1) : '> ';
              } else if (list == 'bullet') {
                // Bullet list: prefix with '- '
                // Example: "- Item 1\n"
                linePrefix += '- ';
              } else if (list == 'ordered') {
                // Ordered list: numbering based on indent level
                // Level 0: 1. 2. 3.
                // Level 1: a. b. c. (with bounds check: max 26, then falls back to numbers)
                // Level 2: i. ii. iii. (Roman numerals)
                int index = orderedListCounter[indentLevel ?? 0] = (orderedListCounter[indentLevel ?? 0] ?? 0) + 1;
                final formattedIndex = switch (indentLevel) {
                  0 => '$index.', // 1. 2. 3.
                  1 =>
                    index <= 26
                        ? '${String.fromCharCode(96 + index)}.' // a. b. c. (up to z)
                        : '$index.', // Fallback to numbers if > 26
                  2 => '${_toRoman(index).toLowerCase()}.', // i. ii. iii.
                  _ => '$index.',
                };
                linePrefix += '$formattedIndex ';
              } else if (list == 'checked') {
                // Checked checkbox: markdown "- [x] " or emoji "✅ "
                linePrefix += markdown ? '- [x] ' : '✅ ';
              } else if (list == 'unchecked') {
                // Unchecked checkbox: markdown "- [ ] " or emoji "⏹️ "
                linePrefix += markdown ? '- [ ] ' : '⏹️ ';
              }

              buffer.write(linePrefix);
              buffer.write(currentLineText);
              buffer.write('\n');
              currentLineText = '';
            }
          }
        } else {
          // Text without newline - just accumulate with formatting
          final formattedText = _applyTextFormatting(insert, attributes, markdown);
          currentLineText += formattedText;
        }
      } else if (insert is Map) {
        // Handle embeds (images, videos, audio, custom embeds)
        // Example: {"insert": {"image": "images/1759081859921.jpg"}}
        final embedType = insert.keys.first;

        if (embedType == 'image' || embedType == 'audio') {
          if (includeMarkdownEmbeds) {
            final url = insert[embedType].toString();

            if (AssetType.values.map((e) => e.subDirectory).any((subDirectory) => url.startsWith(subDirectory))) {
              // Markdown image syntax: ![alt text](../images/001.jpg) when embedRelativePath is '../'
              // Markdown image syntax: ![alt text](images/001.jpg) when embedRelativePath is ''
              currentLineText += '![$embedType]($embedRelativePath$url)';
            } else {
              // Markdown image syntax: ![alt text](url)
              currentLineText += '![$embedType]($url)';
            }
          }
          // Skip images and audio - don't include in text output
        } else {
          // For other embeds (like video), use Unicode object replacement character
          currentLineText += '\uFFFC';
        }
      }
    }

    // Close code block if still open
    if (inCodeBlock) {
      buffer.write('```\n');
    }

    // Flush any remaining line text (text without trailing newline)
    if (currentLineText.isNotEmpty) {
      buffer.write(currentLineText);
    }

    return buffer.toString();
  }

  /// Applies text-level formatting (bold, italic, links) to a text segment.
  ///
  /// Text attributes examples:
  /// - {"bold": true} → "**text**"
  /// - {"italic": true} → "*text*"
  /// - {"bold": true, "italic": true} → "***text***"
  /// - {"link": "https://example.com"} → "[text](https://example.com)"
  ///
  /// [text] - The text content to format
  /// [attributes] - Delta attributes map containing formatting info
  /// [markdown] - Whether to apply markdown formatting
  /// [prefix] - Optional prefix to prepend to the text
  static String _applyTextFormatting(
    String text,
    Map<String, dynamic> attributes,
    bool markdown,
  ) {
    if (!markdown) return text;

    final isBold = attributes.containsKey('bold');
    final isItalic = attributes.containsKey('italic');
    final link = attributes['link'] as String?;

    String result = text;

    if (link != null) {
      // Links: [text](url)
      return '[$text]($link)';
    } else if (isBold && isItalic) {
      // Bold + Italic: ***text***
      result = '***$text***';
    } else if (isBold) {
      // Bold: **text**
      result = '**$text**';
    } else if (isItalic) {
      // Italic: *text*
      result = '*$text*';
    }

    return result;
  }

  /// Converts a number to lowercase Roman numerals.
  ///
  /// Used for nested ordered lists at indent level 2.
  ///
  /// Examples:
  /// - 1 → "i"
  /// - 2 → "ii"
  /// - 3 → "iii"
  /// - 4 → "iv"
  /// - 5 → "v"
  static String _toRoman(int number) {
    final numerals = {
      1000: 'M',
      900: 'CM',
      500: 'D',
      400: 'CD',
      100: 'C',
      90: 'XC',
      50: 'L',
      40: 'XL',
      10: 'X',
      9: 'IX',
      5: 'V',
      4: 'IV',
      1: 'I',
    };

    var result = '';
    var n = number;

    numerals.forEach((value, symbol) {
      while (n >= value) {
        result += symbol;
        n -= value;
      }
    });

    return result;
  }
}
