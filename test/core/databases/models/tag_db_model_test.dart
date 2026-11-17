import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';

void main() {
  group('TagDbModel color', () {
    Map<String, dynamic> json() => TagDbModel.fromIDTitle(1, 'Travel').toJson();

    test('a tag from before colors (no key) has none', () {
      final legacy = json()..remove('color_seed_value');
      expect(TagDbModel.fromJson(legacy).colorSeed, isNull);
    });

    test('keeps its color through JSON (backups)', () {
      final tag = TagDbModel.fromIDTitle(1, 'Travel').copyWith(colorSeedValue: Colors.teal.toARGB32());
      final restored = TagDbModel.fromJson(tag.toJson());
      expect(restored.colorSeed, Color(Colors.teal.toARGB32()));
    });

    test('passing null to copyWith removes the color', () {
      final tag = TagDbModel.fromIDTitle(1, 'Travel').copyWith(colorSeedValue: Colors.teal.toARGB32());
      expect(tag.copyWith(colorSeedValue: null).colorSeedValue, isNull);
    });
  });
}
