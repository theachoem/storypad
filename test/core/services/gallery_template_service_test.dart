import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/gallery_template_category_object.dart';
import 'package:storypad/core/objects/gallery_template_object.dart';
import 'package:storypad/core/services/gallery_template_service.dart';
import 'package:storypad/gen/assets.gen.dart';
import 'package:storypad/gen/storage_hash_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GalleryTemplateService.loadTemplates', () {
    test('should load templates successfully', () async {
      final yamlFiles = Assets.templates.values;

      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          final assetPath = utf8.decode(message!.buffer.asUint8List());
          if (yamlFiles.contains(assetPath)) {
            final content = File(assetPath).readAsStringSync();
            final bytes = utf8.encode(content);
            return ByteData.view(Uint8List.fromList(bytes).buffer);
          }
          return null;
        },
      );

      final result = await GalleryTemplateService.loadTemplates();

      expect(result, isA<Map<GalleryTemplateCategoryObject, List<GalleryTemplateObject>>>());
      expect(result.length, 7); // All 7 categories

      // Check that all expected categories are loaded
      final categoryNames = result.keys.map((c) => c.name).toSet();
      expect(
        categoryNames,
        containsAll([
          'Travel',
          'Creative & Writing',
          'Daily Reflection',
          'Growth & Productivity',
          'Health & Wellness',
          'Reflection & Gratitude',
          'Special Days & Celebrations',
        ]),
      );

      // Ensure each category has at least one template
      for (final category in result.keys) {
        expect(category.templates, isNotEmpty);
      }
    });
  });

  group('GalleryTemplateService icon validation', () {
    test('should validate that icon_url_path exists in kStorageHashMap & is PNG', () async {
      final yamlFiles = Assets.templates.values;

      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          final assetPath = utf8.decode(message!.buffer.asUint8List());
          if (yamlFiles.contains(assetPath)) {
            final content = File(assetPath).readAsStringSync();
            final bytes = utf8.encode(content);
            return ByteData.view(Uint8List.fromList(bytes).buffer);
          }
          return null;
        },
      );

      final result = await GalleryTemplateService.loadTemplates();

      // Validate all templates' icons
      for (final category in result.keys) {
        for (final template in category.templates) {
          // Check that icon_url_path exists in kStorageHashMap
          expect(
            kStorageHashMap.containsKey(template.iconUrlPath),
            isTrue,
            reason: 'Icon ${template.iconUrlPath} not found in kStorageHashMap for template ${template.id}',
          );

          // Check that it ends with .png
          expect(
            template.iconUrlPath.endsWith('.png'),
            isTrue,
            reason: 'Icon ${template.iconUrlPath} does not end with .png for template ${template.id}',
          );
        }
      }
    });
  });
}
