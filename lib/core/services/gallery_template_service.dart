import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:storypad/core/objects/gallery_template_category_object.dart';
import 'package:storypad/core/objects/gallery_template_object.dart';
import 'package:storypad/gen/assets.gen.dart';
import 'package:yaml/yaml.dart';

class GalleryTemplateService {
  static Future<Map<GalleryTemplateCategoryObject, List<GalleryTemplateObject>>> loadTemplates() async {
    final Map<GalleryTemplateCategoryObject, List<GalleryTemplateObject>> templates = {};

    final List<String> yamlFiles = Assets.templates.values..sort((a, b) => a.compareTo(b));

    for (final String path in yamlFiles) {
      final String yamlString = await rootBundle.loadString(path);
      final dynamic yamlData = loadYaml(yamlString);

      final Map<String, dynamic> json = jsonDecode(jsonEncode(yamlData));
      if (json.containsKey('category')) {
        json['name'] = json['category'];
        json.remove('category');
      }

      final GalleryTemplateCategoryObject category = GalleryTemplateCategoryObject.fromJson(json);
      templates[category] = category.templates;
    }

    return templates;
  }
}
