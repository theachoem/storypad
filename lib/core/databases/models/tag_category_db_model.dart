import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/databases/adapters/objectbox/tag_categories_box.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';

part 'tag_category_db_model.g.dart';

@CopyWith()
@JsonSerializable()
class TagCategoryDbModel extends BaseDbModel {
  static final TagCategoriesBox db = TagCategoriesBox();

  @override
  final int id;
  final int index;
  final int version;
  final String _title;
  final bool multiSelect;
  final DateTime createdAt;

  @override
  final DateTime updatedAt;
  final String? lastSavedDeviceId;

  @override
  final DateTime? permanentlyDeletedAt;

  // Custom ID has ID generated from current date, while system ID is predefined and less than 1000.
  bool get system => id < 1000;

  TagCategoryDbModel({
    required this.id,
    required this.version,
    required String title,
    required this.multiSelect,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSavedDeviceId,
    required this.permanentlyDeletedAt,
    int? index,
  }) : _title = title,
       index = index ?? 0;

  static List<String> suggestFeelings = "😄 🥳 🥰 😂 😈 😌 😊 😐 🤔 🧐 😶 😴 😔 😢 😭 😰 🤯 😤 😡 🤒 🥵 🥶 😋".split(
    " ",
  );

  static List<String> suggestActivities =
      "🏃 🚴 🚶 🏋️ 🏊 🧘 ⚽ 💻 📖 📝 🎓 🎨 💼 🍳 🧹 🛒 ☕ 🛌 🛁 🌱 🎮 📺 🎧 🍽️ 🎤 💃 📸 🚗 ✈️ 💇".split(" ");

  static List<String> suggestWeathers = "☀️ 🌤️ ☁️ 🌦️ 🌧️ ⛈️ 🌈 ❄️".split(" ");

  List<TagDbModel> suggestTags() {
    switch (id) {
      case 1:
        return suggestFeelings
            .map((emoji) => TagDbModel.emoji(emoji, categoryId: TagCategoryDbModel.feeling().id))
            .toList();
      case 2:
        return suggestActivities
            .map((emoji) => TagDbModel.emoji(emoji, categoryId: TagCategoryDbModel.activity().id))
            .toList();
      case 3:
        return suggestWeathers
            .map((emoji) => TagDbModel.emoji(emoji, categoryId: TagCategoryDbModel.weather().id))
            .toList();
      default:
        return [];
    }
  }

  String get title {
    if (system) {
      return {
        1: tr("general.tag_category.feeling_title"),
        2: tr("general.tag_category.activity_title"),
        3: tr("general.tag_category.weather_title"),
      }[id]!;
    }

    return _title;
  }

  static List<TagCategoryDbModel> systemCategories = [
    TagCategoryDbModel.feeling(),
    TagCategoryDbModel.activity(),
    TagCategoryDbModel.weather(),
  ];

  factory TagCategoryDbModel.feeling() => TagCategoryDbModel.system(1, "Feeling", multiSelect: false);
  factory TagCategoryDbModel.activity() => TagCategoryDbModel.system(2, "Activity", multiSelect: true);
  factory TagCategoryDbModel.weather() => TagCategoryDbModel.system(3, "Weather", multiSelect: false);
  factory TagCategoryDbModel.system(int id, String title, {bool multiSelect = false}) {
    return TagCategoryDbModel(
      id: id,
      version: 0,
      title: title,
      multiSelect: multiSelect,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastSavedDeviceId: null,
      permanentlyDeletedAt: null,
    );
  }

  factory TagCategoryDbModel.custom({
    required String title,
    bool multiSelect = false,
  }) {
    return TagCategoryDbModel(
      id: DateTime.now().millisecondsSinceEpoch,
      version: 0,
      title: title,
      multiSelect: multiSelect,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastSavedDeviceId: null,
      permanentlyDeletedAt: null,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$TagCategoryDbModelToJson(this);
  factory TagCategoryDbModel.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('index')) json['index'] = 0;
    return _$TagCategoryDbModelFromJson(json);
  }
}
