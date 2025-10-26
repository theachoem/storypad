class MarkdownToQuillDeltaService {
  static List<dynamic>? call(String markdown) {
    if (markdown.isEmpty) {
      return null;
    }
    return [
      {'insert': '$markdown\n'},
    ];
  }
}
