import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor_example/embeds/demo_embeds.dart';

import 'fidelity_audit.dart';

/// Runs the fidelity audit (see `fidelity_audit.dart`).
///
/// On your own backup (nothing leaves your machine; only counts, attribute keys and story ids are printed):
///
/// ```sh
/// cd packages/storypad_editor/example
/// BACKUP=/path/to/backup-or-folder flutter test tool/fidelity_audit_test.dart
/// ```
///
/// Without `BACKUP`, it audits the real-shape fixtures in `test/fixtures/quill/`. Either way it fails unless the
/// conversion is clean: no formatting dropped, no unexpected round-trip difference, no page failing to convert.
void main() {
  final codec = StoryCodec(embeds: demoEmbeds);
  final backup = Platform.environment['BACKUP'];

  test(backup == null ? 'fixtures convert faithfully' : 'the backup converts faithfully', () {
    final pages = backup == null ? _fixturePages() : pagesFromBackups(backup);
    expect(pages, isNotEmpty, reason: 'no pages found${backup == null ? '' : ' in $backup'}');

    final report = audit(codec, pages);
    // ignore: avoid_print
    print(report.format());
    expect(report.isClean, isTrue, reason: 'see the report above');
  });
}

List<AuditPage> _fixturePages() {
  final files = Directory('test/fixtures/quill').listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
  return [
    for (final file in files)
      AuditPage(file.uri.pathSegments.last, jsonDecode(file.readAsStringSync()) as List<Object?>),
  ];
}
