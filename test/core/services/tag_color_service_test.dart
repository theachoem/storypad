import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/tag_color_service.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  group('TagColorService.resolve', () {
    test('is cached per seed and brightness', () {
      final first = TagColorService.resolve(Colors.red, .light);
      expect(identical(TagColorService.resolve(Color(Colors.red.toARGB32()), .light), first), isTrue);
    });

    test('adapts to the brightness', () {
      final light = TagColorService.resolve(Colors.teal, .light);
      final dark = TagColorService.resolve(Colors.teal, .dark);

      expect(light.background, isNot(dark.background));
      expect(light.background.computeLuminance(), greaterThan(dark.background.computeLuminance()));
    });

    test('chip text stays readable for every color in the picker, in both modes', () {
      for (final seed in kMaterialColors) {
        for (final brightness in Brightness.values) {
          final colors = TagColorService.resolve(seed, brightness);
          expect(
            _contrast(colors.background, colors.foreground),
            greaterThanOrEqualTo(4.5),
            reason: '${seed.toARGB32().toRadixString(16)} $brightness',
          );
        }
      }
    });
  });
}
