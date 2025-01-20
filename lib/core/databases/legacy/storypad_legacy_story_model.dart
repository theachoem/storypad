class StorypadLegacyStoryModel {
  final int id;
  final String title;
  final String? paragraph;
  final DateTime createOn;
  final DateTime? updateOn;
  final DateTime forDate;
  final bool isFavorite;
  final String? feeling;

  StorypadLegacyStoryModel({
    required this.id,
    required this.title,
    required this.paragraph,
    required this.createOn,
    required this.forDate,
    this.feeling,
    this.updateOn,
    this.isFavorite = false,
  });

  static StorypadLegacyStoryModel get empty {
    return StorypadLegacyStoryModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: "",
      paragraph: "",
      createOn: DateTime.now(),
      forDate: DateTime.now(),
      feeling: null,
    );
  }

  StorypadLegacyStoryModel copyWith({
    int? id,
    String? title,
    String? paragraph,
    DateTime? createOn,
    DateTime? updateOn,
    DateTime? forDate,
    bool? isFavorite,
    String? feeling,
  }) {
    return StorypadLegacyStoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      paragraph: paragraph ?? this.paragraph,
      createOn: createOn ?? this.createOn,
      forDate: forDate ?? this.forDate,
      updateOn: updateOn ?? this.updateOn,
      isFavorite: isFavorite ?? this.isFavorite,
      feeling: feeling ?? this.feeling,
    );
  }

  factory StorypadLegacyStoryModel.fromJson(Map<dynamic, dynamic> json) {
    final DateTime? createOn = dateTimeFromIntMap(key: 'create_on', json: json);
    final DateTime? forDate = dateTimeFromIntMap(key: 'for_date', json: json);
    final DateTime? updateOn = dateTimeFromIntMap(key: 'update_on', json: json);
    final bool isFavorite = boolFromIntMap(key: 'is_favorite', json: json);

    return StorypadLegacyStoryModel(
      id: json["id"],
      title: json["title"],
      feeling: json["feeling"],
      paragraph: json["paragraph"],
      isFavorite: isFavorite,
      updateOn: updateOn,
      createOn: createOn ?? DateTime.now(),
      forDate: forDate ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "feeling": feeling,
      "paragraph": paragraph,
      "is_favorite": isFavorite ? 1 : 0,
      "create_on": intFromDateTime(dateTime: createOn),
      "for_date": intFromDateTime(dateTime: forDate),
      "update_on": intFromDateTime(dateTime: updateOn),
    };
  }

  static DateTime? dateTimeFromIntMap({
    Map<dynamic, dynamic>? json,
    String? key,
  }) {
    if (key == null) return null;
    if (json == null) return null;

    if (json.containsKey(key) && json[key] is int) {
      return DateTime.fromMillisecondsSinceEpoch(json[key]);
    } else {
      return null;
    }
  }

  static bool boolFromIntMap({
    Map<dynamic, dynamic>? json,
    String? key,
  }) {
    if (key == null) return false;
    if (json == null) return false;

    if (json.containsKey(key) && json[key] is int) {
      return json[key] == 1 ? true : false;
    } else {
      return false;
    }
  }

  static int? intFromDateTime({DateTime? dateTime}) {
    if (dateTime == null) return null;
    return dateTime.millisecondsSinceEpoch;
  }
}
