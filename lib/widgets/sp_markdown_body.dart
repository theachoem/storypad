import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpMarkdownBody extends StatelessWidget {
  const SpMarkdownBody({
    super.key,
    required this.body,
    this.align = WrapAlignment.start,
  });

  final String body;
  final WrapAlignment align;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: body,
      onTapLink: (text, href, title) => UrlOpenerService.openForMarkdown(
        context: context,
        text: text,
        href: href,
        title: title,
      ),
      styleSheet: MarkdownStyleSheet(
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
