import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpMarkdownBody extends StatelessWidget {
  const SpMarkdownBody({
    super.key,
    required this.body,
    this.align = WrapAlignment.start,
    this.onTapLink,
    this.style,
  });

  final String body;
  final WrapAlignment align;
  final void Function(String, String?, String)? onTapLink;
  final TextStyle? style;

  /// [markdown] with no loose lists, so every task shows its checkbox.
  ///
  /// A blank line between two list items makes a loose list, whose items' text sits in a paragraph -- and
  /// flutter_markdown_plus shows a task's checkbox only when it's the item's first child, not inside that paragraph,
  /// so the task shows a bullet. Blank lines between list items come from an empty line between them in the story.
  /// Before a top-level item, the blank line becomes an `&nbsp;` line (as the story stores it): two tight lists with
  /// the empty line still showing. Before an indented item it's dropped instead -- an indented line after a paragraph
  /// would read as code.
  @visibleForTesting
  static String withoutLooseLists(String markdown) {
    if (!_blankLine.hasMatch(markdown)) return markdown;

    final lines = markdown.split('\n');
    final result = <String>[];
    // The open code fence's run (e.g. ``` or ~~~~), null outside code.
    String? fence;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      fence = _fenceAfter(line, fence);

      final isBlank = line.trim().isEmpty;
      if (fence != null || !isBlank || result.isEmpty || !_listLine.hasMatch(result.last)) {
        result.add(line);
        continue;
      }

      // A run of blank lines right after a list item: look at what follows it.
      var next = i;
      while (next < lines.length && lines[next].trim().isEmpty) {
        next++;
      }
      if (next == lines.length || !_listLine.hasMatch(lines[next])) {
        result.add(line);
        continue;
      }

      if (!lines[next].startsWith(RegExp(r'[ \t]'))) result.addAll(['', '&nbsp;', '']);
      i = next - 1;
    }
    return result.join('\n');
  }

  /// The open fence after [line], [open] being the one before it. As in CommonMark: a fence is 3+ backticks or
  /// tildes (backticks with no backtick after them), closed only by a run of the same character at least as long
  /// with nothing after it -- so a ``` line inside a ```` block, or a tilde-fenced block, is still code.
  static String? _fenceAfter(String line, String? open) {
    final match = _fence.firstMatch(line);
    if (match == null) return open;

    final run = match.group(1)!;
    final rest = match.group(2)!;
    if (open == null) return run.startsWith('`') && rest.contains('`') ? null : run;

    final closes = run[0] == open[0] && run.length >= open.length && rest.trim().isEmpty;
    return closes ? null : open;
  }

  static final _fence = RegExp(r'^[ \t]*(`{3,}|~{3,})(.*)$');
  static final _blankLine = RegExp(r'\n[ \t]*\n');
  static final _listLine = RegExp(r'^[ \t]*(?:[-*+]|\d{1,9}[.)])(?:[ \t]|$)');

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: withoutLooseLists(body),
      onTapLink:
          onTapLink ?? (text, href, title) => UrlOpenerService.openForRichContent(context: context, url: href ?? ''),
      styleSheet: MarkdownStyleSheet(
        p: style,
        textAlign: align,
        blockquoteDecoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            left: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        blockquotePadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8.0),
        codeblockDecoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor)),
        listBulletPadding: const EdgeInsets.all(2),
        listIndent: 16,
        blockSpacing: 4.0,
      ),
      checkboxBuilder: (checked) {
        return Transform.translate(
          offset: const Offset(-3.5, 2.5),
          child: Icon(
            checked ? SpIcons.checkbox : SpIcons.checkboxBlank,
            size: 16.0,
          ),
        );
      },
      softLineBreak: true,
    );
  }
}
