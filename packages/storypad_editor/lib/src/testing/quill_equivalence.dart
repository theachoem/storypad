import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

import '../codec/story_codec.dart';
import '../quill/quill_canonical.dart';

export '../quill/quill_canonical.dart' show canonicalQuill;

/// Matches Quill ops (a `List`) equivalent to [expected] as [canonicalQuill] sees them.
Matcher isEquivalentQuill(List<Object?> expected, StoryCodec codec) => _EquivalentQuill(expected, codec);

String _describe(List<Map<String, Object?>> lines) {
  return lines.map((line) => jsonEncode(line, toEncodable: (value) => value.toString())).join('\n  ');
}

class _EquivalentQuill extends Matcher {
  _EquivalentQuill(List<Object?> expected, this.codec) : expected = canonicalQuill(expected, codec);

  final List<Map<String, Object?>> expected;
  final StoryCodec codec;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! List) return false;
    return const DeepCollectionEquality().equals(canonicalQuill(item, codec), expected);
  }

  @override
  Description describe(Description description) => description.add('Quill equivalent to:\n  ${_describe(expected)}');

  @override
  Description describeMismatch(Object? item, Description mismatch, Map<dynamic, dynamic> matchState, bool verbose) {
    if (item is! List) return mismatch.add('is not a list of ops');
    return mismatch.add('reads as:\n  ${_describe(canonicalQuill(item, codec))}');
  }
}
