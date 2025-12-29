/// Filters out markdown structural and decorative elements from text content.
///
/// Used to extract only actual written content before counting characters and words.
///
/// Removes:
/// - Checkboxes (unchecked): `- [ ]` or `⏹️` - Intent markers, not content
/// - Bullet markers: `- `, `* `, `1. `, `a. `, etc. - Formatting
/// - Markdown syntax: `##`, `**`, `*`, `__`, `_`, `[]()`, etc. - Formatting
/// - Horizontal rules: `---`, `***`, `___` - Layout elements
/// - Blockquote markers: `>`, `> >`, etc. - Formatting
/// - Code block markers: ` ``` ` - Formatting
/// - Embedded widgets: Unicode object replacement character `\uFFFC` - Non-text content
/// - List indentation: tabs at start of lines - Formatting
class MarkdownContentFilterService {
  /// Filters out all markdown structural and decorative elements.
  ///
  /// [text] - The markdown-formatted text to filter
  ///
  /// Returns filtered text with only actual written content.
  static String call(String text) {
    if (text.isEmpty) return text;

    final lines = text.split('\n');
    final sanitizedLines = <String>[];

    for (var line in lines) {
      var sanitized = line;

      // Remove leading tabs (indentation)
      sanitized = sanitized.replaceAll(RegExp(r'^\t+'), '');

      // Remove blockquote markers (>, > >, etc.)
      sanitized = sanitized.replaceAll(RegExp(r'^(> )+'), '');

      // Remove unchecked checkbox markers
      // Markdown: - [ ]
      sanitized = sanitized.replaceAll(RegExp(r'^- \[ \] '), '');
      // Emoji: ⏹️
      sanitized = sanitized.replaceAll(RegExp(r'^⏹️ '), '');

      // Remove checked checkbox markers (keeping content but removing marker)
      // Markdown: - [x]
      sanitized = sanitized.replaceAll(RegExp(r'^- \[x\] '), '');
      // Emoji: ✅
      sanitized = sanitized.replaceAll(RegExp(r'^✅ '), '');

      // Remove bullet list markers (-, *, •)
      sanitized = sanitized.replaceAll(RegExp(r'^[-*•] '), '');

      // Remove ordered list markers (1., 2., a., b., i., ii., etc.)
      // Numbers: 1. 2. 3. etc.
      sanitized = sanitized.replaceAll(RegExp(r'^\d+\. '), '');
      // Letters: a. b. c. etc.
      sanitized = sanitized.replaceAll(RegExp(r'^[a-z]\. '), '');
      // Roman numerals: i. ii. iii. iv. etc.
      sanitized = sanitized.replaceAll(RegExp(r'^[ivxlcdm]+\. '), '');

      // Remove code block markers
      sanitized = sanitized.replaceAll('```', '');

      // Remove horizontal rule lines (must be on their own line)
      if (RegExp(r'^[-*_]{3,}$').hasMatch(sanitized.trim())) {
        continue; // Skip this line entirely
      }

      // Remove embedded widget markers (object replacement character)
      sanitized = sanitized.replaceAll('\uFFFC', '');

      // Remove inline markdown formatting
      // Bold+Italic: ***text*** (must be before bold and italic)
      sanitized = sanitized.replaceAllMapped(
        RegExp(r'\*\*\*([^*]+)\*\*\*'),
        (match) => match.group(1)!,
      );

      // Bold: **text** or __text__
      sanitized = sanitized.replaceAllMapped(
        RegExp(r'\*\*([^*]+)\*\*'),
        (match) => match.group(1)!,
      );
      sanitized = sanitized.replaceAllMapped(
        RegExp(r'__([^_]+)__'),
        (match) => match.group(1)!,
      );

      // Italic: *text* or _text* (but not inside words)
      sanitized = sanitized.replaceAllMapped(
        RegExp(r'\*([^*]+)\*'),
        (match) => match.group(1)!,
      );
      sanitized = sanitized.replaceAllMapped(
        RegExp(r'\b_([^_]+)_\b'),
        (match) => match.group(1)!,
      );

      // Strikethrough: ~~text~~
      sanitized = sanitized.replaceAllMapped(
        RegExp(r'~~([^~]+)~~'),
        (match) => match.group(1)!,
      );

      // Inline code: `code`
      sanitized = sanitized.replaceAllMapped(
        RegExp(r'`([^`]+)`'),
        (match) => match.group(1)!,
      );

      // Images: ![alt](url) -> remove entirely (it's not text content) (must be before links)
      sanitized = sanitized.replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]+\)'), '');

      // Links: [text](url) -> keep only text
      sanitized = sanitized.replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]+\)'),
        (match) => match.group(1)!,
      );

      // Headers: ## text -> text
      sanitized = sanitized.replaceAll(RegExp(r'^#{1,6}\s+'), '');

      // Add sanitized line if it's not empty after sanitization
      if (sanitized.trim().isNotEmpty) {
        sanitizedLines.add(sanitized);
      }
    }

    return sanitizedLines.join('\n');
  }
}
