import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/story_plain_text_exporter.dart';
import 'package:storypad/core/types/time_format_option.dart';
import 'package:storypad/widgets/rich_editor/sp_embeds.dart';

void main() {
  final date = DateTime(2026, 11, 9, 8, 30);
  // intl's one locale with no setup.
  const locale = Locale('en', 'US');

  String export(List<String> pages, {required bool markdown}) {
    final text = StoryPlainTextExporter(
      displayPathDate: date,
      pages: pages.map(SpEmbeds.codec.decodeNodes).toList(),
      tags: const [],
      emojis: const ['😀'],
      timeFormat: TimeFormatOption.h24,
      locale: locale,
      markdown: markdown,
    ).export();

    // Just the pages, between the header and the hashtag.
    final header = '${TimeFormatOption.h24.formatDateTime(date, locale)}\n😀\n\n';
    expect(text, startsWith(header));
    expect(text, endsWith('\n\n#StoryPad'));
    return text.substring(header.length, text.length - '\n\n#StoryPad'.length);
  }

  const page = '''
### My day

Went **out** with *friends*, see [map](https://example.com) and ~~not~~ `this`.

&nbsp;

![](images/1.jpg)

![](images/2.jpg)

## Plans

1. First
    1. Nested
    2. Again
2. Second

- Bullet

1. Restarted

- [x] Done
- [ ] Todo

> Quoted

```
code **here**
```''';

  test('plain text drops formatting and embeds, keeping list markers', () {
    expect(export([page], markdown: false), '''
My day
Went out with friends, see map and not this.

Plans
1. First
\ta. Nested
\tb. Again
2. Second
- Bullet
1. Restarted
✅ Done
⏹️ Todo
> Quoted
code **here**''');
  });

  test('markdown keeps headings and inline formatting, without storage syntax', () {
    expect(export([page], markdown: true), '''
### My day
Went **out** with *friends*, see [map](https://example.com) and ~~not~~ `this`.

## Plans
1. First
\t1. Nested
\t2. Again
2. Second
- Bullet
1. Restarted
- [x] Done
- [ ] Todo
> Quoted
```
code **here**
```''');
  });

  test('pages are separated by a rule, and empty pages are skipped', () {
    expect(export(['### One', '###', 'Two'], markdown: false), 'One\n\n---\n\nTwo');
  });
}
