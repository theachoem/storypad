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

// CIE76 color difference (Lab, D65): about 2 is barely noticeable. The colors left out of the tag
// palette for looking alike come out at 1–6.5 against a kept one; the kept ones are 10+ apart.
double _deltaE(Color a, Color b) {
  List<double> lab(Color c) {
    double linear(double v) => v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
    final r = linear(c.r), g = linear(c.g), b = linear(c.b);
    final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
    final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
    double f(double t) => t > 0.008856 ? pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
    return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
  }

  final la = lab(a), lb = lab(b);
  return sqrt(pow(la[0] - lb[0], 2) + pow(la[1] - lb[1], 2) + pow(la[2] - lb[2], 2));
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

    // What the edit tag page offers: no two chips, or swatches, that look alike.
    test('every color in the tag palette makes a distinct chip and swatch, in both modes', () {
      const palette = TagColorService.palette;
      for (final brightness in Brightness.values) {
        for (var i = 0; i < palette.length; i++) {
          for (var j = i + 1; j < palette.length; j++) {
            final a = TagColorService.resolve(palette[i], brightness);
            final b = TagColorService.resolve(palette[j], brightness);
            final reason = '$i vs $j, $brightness';
            expect(_deltaE(a.background, b.background), greaterThanOrEqualTo(8), reason: reason);
            expect(_deltaE(a.swatch, b.swatch), greaterThanOrEqualTo(8), reason: reason);
          }
        }
      }
    });
  });
}
