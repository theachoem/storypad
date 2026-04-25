import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/tag_id_generator_service.dart';

void main() {
  group('TagIdGeneratorService', () {
    const cutoff = TagIdGeneratorService.cutoff;

    group('.cutoff', () {
      test('cutoff equals 1 << 60', () {
        expect(cutoff, equals(1 << 60));
      });
    });

    group('.timeId', () {
      test('returns value less than cutoff', () {
        final id = TagIdGeneratorService.timeId();
        expect(id, lessThan(cutoff));
      });

      test('isTime returns true for timeId', () {
        final id = TagIdGeneratorService.timeId();
        expect(TagIdGeneratorService.isTime(id), isTrue);
        expect(TagIdGeneratorService.isEmoji(id), isFalse);
      });
    });

    group('.emojiId', () {
      test('returns value >= cutoff', () {
        final id = TagIdGeneratorService.emojiId('😊');
        expect(id, greaterThanOrEqualTo(cutoff));
      });

      test('same emoji produces same ID (deterministic)', () {
        final id1 = TagIdGeneratorService.emojiId('😊');
        final id2 = TagIdGeneratorService.emojiId('😊');
        expect(id1, equals(id2));
      });

      test('different emojis produce different IDs', () {
        final id1 = TagIdGeneratorService.emojiId('😊');
        final id2 = TagIdGeneratorService.emojiId('🔥');
        expect(id1, isNot(equals(id2)));
      });

      test('works with multi-codepoint emoji', () {
        final id = TagIdGeneratorService.emojiId('👨‍👩‍👧‍👦');
        expect(id, greaterThanOrEqualTo(cutoff));
      });

      test('isEmoji returns true for emojiId', () {
        final id = TagIdGeneratorService.emojiId('🌟');
        expect(TagIdGeneratorService.isEmoji(id), isTrue);
        expect(TagIdGeneratorService.isTime(id), isFalse);
      });
    });

    // ==============================
    // isEmoji / isTime
    // ==============================
    group('isEmoji and isTime', () {
      test('isEmoji is false for value below cutoff', () {
        expect(TagIdGeneratorService.isEmoji(cutoff - 1), isFalse);
      });

      test('isEmoji is true for value equal to cutoff', () {
        expect(TagIdGeneratorService.isEmoji(cutoff), isTrue);
      });

      test('isTime is true for value below cutoff', () {
        expect(TagIdGeneratorService.isTime(cutoff - 1), isTrue);
      });

      test('isTime is false for value equal to cutoff', () {
        expect(TagIdGeneratorService.isTime(cutoff), isFalse);
      });

      test('isEmoji and isTime are mutually exclusive', () {
        for (final id in [0, 1000, cutoff - 1, cutoff, cutoff + 1, cutoff + 999999]) {
          expect(TagIdGeneratorService.isEmoji(id) == TagIdGeneratorService.isTime(id), isFalse);
        }
      });
    });
  });
}
