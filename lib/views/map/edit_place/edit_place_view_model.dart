import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'edit_place_view.dart';

class EditPlaceViewModel extends ChangeNotifier with DisposeAwareMixin {
  final EditPlaceRoute params;

  late final TextEditingController labelController;

  List<String> _recentLabels = <String>[];
  List<String> get recentLabels => _recentLabels;

  String get initialLabel => params.place.placeName?.trim() ?? '';
  String get normalizedLabel => _normalize(labelController.text);
  bool get canApply => normalizedLabel != initialLabel;

  EditPlaceViewModel({
    required this.params,
  }) {
    labelController = TextEditingController(text: initialLabel);
    _loadRecentLabels();
  }

  @override
  void dispose() {
    labelController.dispose();
    super.dispose();
  }

  void onLabelChanged(String _) {
    notifyListeners();
  }

  void useLabelSuggestion(String label) {
    labelController
      ..text = label
      ..selection = TextSelection.collapsed(offset: label.length);
    notifyListeners();
  }

  void apply(BuildContext context) {
    Navigator.of(context).pop(canApply ? normalizedLabel : null);
  }

  Future<void> _loadRecentLabels() async {
    final stories = await StoryDbModel.db.getStoriesWithLocation(limit: 50);
    _recentLabels = stories
        .map((e) => e.placeName?.trim())
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    _recentLabels = _recentLabels.take(10).toList();
    notifyListeners();
  }

  String _normalize(String? value) {
    return value?.trim() ?? '';
  }
}
