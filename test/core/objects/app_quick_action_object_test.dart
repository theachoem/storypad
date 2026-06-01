import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/app_quick_action_object.dart';

void main() {
  group('AppQuickActionObject toId / tryFromId round-trip', () {
    AppQuickActionObject roundTrip(AppQuickActionObject original) {
      final osKey = original.toId();
      final decoded = AppQuickActionObject.tryFromId(osKey);
      expect(decoded, isNotNull, reason: 'tryFromId returned null for ${original.key}');
      return decoded!;
    }

    group('default actions', () {
      for (final actionType in AppDefaultQuickActionType.values) {
        test('round-trips ${actionType.id}', () {
          final original = AppQuickActionObject(
            label: 'Test Label',
            type: AppQuickActionType.defaultAction,
            nativeIcon: actionType.nativeIcon,
            defaultActionType: actionType,
          );
          final decoded = roundTrip(original);
          expect(decoded.defaultActionType, actionType);
          expect(decoded.label, original.label);
          expect(decoded.nativeIcon, original.nativeIcon);
          expect(decoded.key, actionType.id);
        });
      }
    });

    group('tag actions', () {
      test('round-trips tag with label and emoji', () {
        const original = AppQuickActionObject(
          label: '🌟 My Tag',
          type: AppQuickActionType.tag,
          nativeIcon: AppQuickActionObject.tagNativeIcon,
          tagId: 42,
        );
        final decoded = roundTrip(original);
        expect(decoded.tagId, 42);
        expect(decoded.label, '🌟 My Tag');
        expect(decoded.key, 'tag:42');
      });
    });

    group('template actions — custom', () {
      test('round-trips custom template', () {
        const original = AppQuickActionObject(
          label: 'My Template',
          type: AppQuickActionType.template,
          nativeIcon: AppQuickActionObject.templateNativeIcon,
          templateReference: AppQuickActionTemplateReference(
            type: AppQuickActionTemplateType.custom,
            id: '123',
          ),
        );
        final decoded = roundTrip(original);
        expect(decoded.templateReference?.type, AppQuickActionTemplateType.custom);
        expect(decoded.templateReference?.id, '123');
        expect(decoded.label, 'My Template');
        expect(decoded.key, 'template:custom:123');
      });
    });

    group('template actions — gallery', () {
      test('round-trips gallery template', () {
        const original = AppQuickActionObject(
          label: 'Daily Journal',
          type: AppQuickActionType.template,
          nativeIcon: AppQuickActionObject.templateNativeIcon,
          templateReference: AppQuickActionTemplateReference(
            type: AppQuickActionTemplateType.gallery,
            id: 'daily_journal',
          ),
        );
        final decoded = roundTrip(original);
        expect(decoded.templateReference?.type, AppQuickActionTemplateType.gallery);
        expect(decoded.templateReference?.id, 'daily_journal');
        expect(decoded.key, 'template:gallery:daily_journal');
      });
    });

    group('key computed getter', () {
      test('default action key matches AppDefaultQuickActionType.id', () {
        for (final actionType in AppDefaultQuickActionType.values) {
          final object = AppQuickActionObject(
            label: '',
            type: AppQuickActionType.defaultAction,
            defaultActionType: actionType,
          );
          expect(object.key, actionType.id);
        }
      });

      test('tag key is tag:<tagId>', () {
        const object = AppQuickActionObject(label: '', type: AppQuickActionType.tag, tagId: 7);
        expect(object.key, 'tag:7');
      });

      test('template key is template:<type>:<id>', () {
        const object = AppQuickActionObject(
          label: '',
          type: AppQuickActionType.template,
          templateReference: AppQuickActionTemplateReference(
            type: AppQuickActionTemplateType.custom,
            id: '99',
          ),
        );
        expect(object.key, 'template:custom:99');
      });
    });

    group('toId reproducibility', () {
      test('same object always produces the same os key', () {
        const object = AppQuickActionObject(
          label: 'Personal',
          type: AppQuickActionType.tag,
          nativeIcon: AppQuickActionObject.tagNativeIcon,
          tagId: 7,
        );
        expect(object.toId(), object.toId());
      });

      test('different labels produce different os keys', () {
        const a = AppQuickActionObject(label: 'Personal', type: AppQuickActionType.tag, tagId: 7);
        const b = AppQuickActionObject(label: 'Work', type: AppQuickActionType.tag, tagId: 7);
        expect(a.toId(), isNot(b.toId()));
      });
    });

    group('tryFromId invalid inputs', () {
      test('returns null for empty string', () {
        expect(AppQuickActionObject.tryFromId(''), isNull);
      });

      test('returns null for arbitrary string', () {
        expect(AppQuickActionObject.tryFromId('not_base64!!!'), isNull);
      });

      test('returns null for valid base64 that is not a JSON object', () {
        expect(AppQuickActionObject.tryFromId('aGVsbG8='), isNull);
      });
    });
  });
}
