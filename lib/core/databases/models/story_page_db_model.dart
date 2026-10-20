import 'package:storypad/widgets/rich_editor/sp_embeds.dart';
import 'package:storypad_editor/storypad_editor.dart';

int _idFromJson(dynamic id) {
  if (id is int) {
    return id;
  } else {
    return DateTime.now().millisecondsSinceEpoch;
  }
}

/// How a page's content is stored.
enum StoryPageFormat {
  /// Markdown ([StoryPageDbModel.markdown]) with the page title as its first block, a heading.
  markdownV1('markdown_v1');

  const StoryPageFormat(this.id);

  /// The value stored in the page's `format` field.
  final String id;

  static StoryPageFormat? fromId(String id) => values.where((format) => format.id == id).firstOrNull;
}

/// One page of a story (or template).
///
/// A page is stored in one of three shapes, told apart by its `format` field:
///
/// - **legacy** (no `format`): a separate `title` and a Quill Delta `body`, as every page was stored before Markdown.
///   Read as Markdown through [markdown] (the title becomes a leading heading) and converted for good by
///   [toMarkdownPage] -- when [checkConversion] finds it lossless.
/// - **Markdown** ([StoryPageFormat.markdownV1]): `markdown`, the title being its first block, a heading.
/// - **unsupported**: a `format` this version doesn't know (written by a newer app). Kept exactly as stored, shown
///   read-only, never edited.
///
/// Readers don't need to know the shape: [markdown], [title] and [quillBody] work for all of them.
class StoryPageDbModel {
  /// A Markdown page.
  StoryPageDbModel.markdown({required this.id, required String markdown, this.wordCount, this.characterCount})
    : format = StoryPageFormat.markdownV1,
      _markdown = markdown,
      _legacyTitle = null,
      _legacyBody = null,
      _unsupportedJson = null;

  /// A new page: [body] (Markdown), after [title] as its leading heading when there's one (e.g. from a template). A
  /// blank page is just empty: nothing special marks a title; it's worked out from the page when it's saved.
  factory StoryPageDbModel.create({required int id, String? title, String body = ''}) {
    final heading = PageTitle.normalize(title);
    return StoryPageDbModel.markdown(
      id: id,
      markdown: SpEmbeds.codec.encode([
        if (heading != null) PageTitle.node(heading),
        ...SpEmbeds.codec.decodeNodes(body),
      ]),
    );
  }

  /// A page in the legacy shape: a separate [title] and a Quill Delta [body]. Only for content from before Markdown
  /// (old databases, backups and imports) -- new pages are [StoryPageDbModel.markdown].
  StoryPageDbModel.legacy({required this.id, String? title, List<dynamic>? body, this.wordCount, this.characterCount})
    : format = null,
      _markdown = null,
      _legacyTitle = title,
      _legacyBody = body,
      _unsupportedJson = null;

  StoryPageDbModel._unsupported(Map<String, dynamic> json)
    : id = _idFromJson(json['id']),
      format = null,
      wordCount = (json['word_count'] as num?)?.toInt(),
      characterCount = (json['character_count'] as num?)?.toInt(),
      _markdown = json['markdown'] is String ? json['markdown'] as String : '',
      _legacyTitle = null,
      _legacyBody = null,
      _unsupportedJson = Map.unmodifiable(json);

  factory StoryPageDbModel.fromJson(Map<String, dynamic> json) {
    final id = _idFromJson(json['id']);
    final wordCount = (json['word_count'] as num?)?.toInt();
    final characterCount = (json['character_count'] as num?)?.toInt();
    final formatId = json['format'];

    if (formatId == null) {
      return StoryPageDbModel.legacy(
        id: id,
        title: json['title'] as String?,
        body: json['body'] as List<dynamic>?,
        wordCount: wordCount,
        characterCount: characterCount,
      );
    }

    return switch (StoryPageFormat.fromId('$formatId')) {
      StoryPageFormat.markdownV1 => StoryPageDbModel.markdown(
        id: id,
        markdown: json['markdown'] as String? ?? '',
        wordCount: wordCount,
        characterCount: characterCount,
      ),
      null => StoryPageDbModel._unsupported(json),
    };
  }

  final int id;
  final int? wordCount;
  final int? characterCount;

  /// How this page is stored: `null` for a legacy or an unsupported page (see [isLegacy], [isUnsupported]).
  final StoryPageFormat? format;

  final String? _markdown;
  final String? _legacyTitle;
  final List<dynamic>? _legacyBody;
  final Map<String, dynamic>? _unsupportedJson;

  /// Stored as a separate title and a Quill Delta body, not converted to Markdown yet.
  bool get isLegacy => format == null && _unsupportedJson == null;

  /// Stored in a format this app version doesn't know (from a newer version): show read-only, never save.
  bool get isUnsupported => _unsupportedJson != null;

  /// The page as Markdown, title included (its first block, a heading). A legacy page is converted on first access.
  late final String markdown = isLegacy
      ? SpEmbeds.codec.quillPageToMarkdown(_legacyBody ?? const [], title: _legacyTitle)
      : _markdown!;

  /// The page title (see `StoryCodec.pageTitleOf`), or `null`. For a legacy page, its stored title.
  String? get title => isLegacy ? _legacyTitle : _derived.title;

  /// The page body -- without the title -- as Quill Delta ops, for readers built on Quill (plain text, word counts,
  /// asset links, exports). A legacy page's stored body; a Markdown page's body written as Quill, which is equivalent
  /// to the Quill it was converted from (see [checkConversion]) -- except that an untitled page starting with a
  /// heading reads that heading as its [title] once converted, so it's no longer part of the body, and that the empty
  /// lines which only spaced embeds out are gone (embeds get space of their own, see `SpEmbeds.codec`).
  List<dynamic> get quillBody => isLegacy ? (_legacyBody ?? const []) : _derived.quillBody;

  late final _MarkdownDerived _derived = _MarkdownDerived.of(markdown);

  /// Whether this legacy page converts to Markdown without losing anything (see `StoryCodec.checkQuillPage`).
  QuillPageCheck checkConversion() {
    assert(isLegacy, 'Only a legacy page is converted.');
    return SpEmbeds.codec.checkQuillPage(_legacyBody ?? const [], title: _legacyTitle, markdown: markdown);
  }

  /// This page stored as Markdown: a legacy page converted (see [checkConversion] first); any other page as is.
  StoryPageDbModel toMarkdownPage() {
    if (!isLegacy) return this;
    return StoryPageDbModel.markdown(
      id: id,
      markdown: markdown,
      wordCount: wordCount,
      characterCount: characterCount,
    );
  }

  /// A Markdown page with this page's id holding [markdown] (e.g. after an edit).
  StoryPageDbModel withMarkdown(String markdown) {
    return StoryPageDbModel.markdown(
      id: id,
      markdown: markdown,
      wordCount: wordCount,
      characterCount: characterCount,
    );
  }

  /// This page with other ids or counts; the content is kept as stored.
  StoryPageDbModel copyWith({int? id, int? wordCount, int? characterCount}) {
    if ((id ?? this.id) == this.id &&
        (wordCount ?? this.wordCount) == this.wordCount &&
        (characterCount ?? this.characterCount) == this.characterCount) {
      return this;
    }
    final json = toJson();
    if (id != null) json['id'] = id;
    if (wordCount != null) json['word_count'] = wordCount;
    if (characterCount != null) json['character_count'] = characterCount;
    return StoryPageDbModel.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    if (_unsupportedJson case final json?) {
      // Verbatim: only what was stored, or changed since (see [copyWith]).
      return {
        ...json,
        if (json['id'] is int) 'id': id,
        if (wordCount != null || json.containsKey('word_count')) 'word_count': wordCount,
        if (characterCount != null || json.containsKey('character_count')) 'character_count': characterCount,
      };
    }
    if (isLegacy) {
      return {
        'id': id,
        'title': _legacyTitle,
        'word_count': wordCount,
        'character_count': characterCount,
        'body': _legacyBody,
      };
    }
    return {
      'id': id,
      'format': format!.id,
      'word_count': wordCount,
      'character_count': characterCount,
      'markdown': _markdown,
    };
  }
}

/// What's worked out from a Markdown page (parsing it is the costly part), shared by every page model holding the same
/// Markdown: while editing, each keystroke rebuilds the story's page models and recounts every page, and all but the
/// edited one are unchanged.
class _MarkdownDerived {
  _MarkdownDerived._(this.title, this.quillBody);

  final String? title;
  final List<dynamic> quillBody;

  static const _maxCached = 64;
  static final Map<String, _MarkdownDerived> _cache = {};

  factory _MarkdownDerived.of(String markdown) {
    final cached = _cache.remove(markdown);
    if (cached != null) return _cache[markdown] = cached; // Most recently used last.

    final nodes = SpEmbeds.codec.decodeNodes(markdown);
    final derived = _MarkdownDerived._(
      StoryCodec.pageTitleOf(nodes),
      List.unmodifiable(SpEmbeds.codec.encodeQuill(StoryCodec.pageBodyOf(nodes))),
    );
    _cache[markdown] = derived;
    if (_cache.length > _maxCached) _cache.remove(_cache.keys.first);
    return derived;
  }
}
