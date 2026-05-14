import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/home_quick_actions/home_quick_actions_view.dart';
import 'package:storypad/views/templates/templates_view.dart';
import 'package:storypad/widgets/sp_icons.dart';

enum HomeQuickActionType { defaultAction, template, tag }

class HomeQuickActionItem {
  const HomeQuickActionItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.type,
    this.subtitle,
  });

  final String id;
  final String label;
  final String? subtitle;
  final IconData icon;
  final HomeQuickActionType type;
}

class HomeQuickActionsViewModel extends ChangeNotifier with DisposeAwareMixin {
  HomeQuickActionsViewModel({
    required this.params,
    required BuildContext context,
  }) {
    isProUser = context.read<InAppPurchaseProvider>().isProUser;
  }

  final HomeQuickActionsRoute params;

  late final bool isProUser;

  final int actionLimit = 5;

  late List<HomeQuickActionItem> enabledActions = [];

  final List<HomeQuickActionItem> defaultActions = [
    HomeQuickActionItem(
      id: 'new_story',
      label: tr('button.new_story'),
      icon: SpIcons.newStory,
      type: HomeQuickActionType.defaultAction,
    ),
    HomeQuickActionItem(
      id: 'take_photo',
      label: tr('button.take_photo'),
      icon: SpIcons.camera,
      type: HomeQuickActionType.defaultAction,
    ),
    HomeQuickActionItem(
      id: 'record_voice',
      label: tr('button.record_voice'),
      icon: SpIcons.voice,
      type: HomeQuickActionType.defaultAction,
    ),
  ];

  final GlobalKey<AnimatedListState> availableActionsListKey = GlobalKey<AnimatedListState>();

  // Tracks the items currently visible in the AnimatedList.
  // Starts empty because all defaultActions are already in enabledActions.
  final List<HomeQuickActionItem> availableItems = [];
  final Set<String> _activatingIds = <String>{};
  final Map<String, Timer> _syncTimers = <String, Timer>{};

  Widget Function(HomeQuickActionItem, Animation<double>)? _availableTileBuilder;
  void setAvailableTileBuilder(Widget Function(HomeQuickActionItem, Animation<double>) builder) {
    _availableTileBuilder = builder;
  }

  bool isActivating(String actionId) => _activatingIds.contains(actionId);

  bool get limitReached => enabledActions.length >= actionLimit;
  int get enabledCount => enabledActions.length;
  double get capacity => enabledCount / actionLimit;

  List<int> get selectedTagIds {
    return enabledActions
        .where((action) => action.type == HomeQuickActionType.tag)
        .map((action) => int.tryParse(action.id.replaceFirst('tag:', '')))
        .whereType<int>()
        .toList();
  }

  bool isEnabled(String id) {
    return enabledActions.any((action) => action.id == id);
  }

  void addAction(HomeQuickActionItem action) {
    if (limitReached || isEnabled(action.id)) return;
    final idx = availableItems.indexWhere((a) => a.id == action.id);
    if (idx != -1) {
      final removed = availableItems.removeAt(idx);
      availableActionsListKey.currentState?.removeItem(
        idx,
        (ctx, anim) => _availableTileBuilder?.call(removed, anim) ?? const SizedBox.shrink(),
      );
    }
    enabledActions.add(action);
    _markActionAsSyncing(action.id);
    notifyListeners();
  }

  void addTemplate(TemplatePickResult result) {
    final action = HomeQuickActionItem(
      id: 'template:${result.type.name}:${result.id}',
      label: result.label,
      subtitle: result.type == TemplatePickResultType.gallery ? 'Gallery Template' : 'Template',
      icon: SpIcons.file,
      type: HomeQuickActionType.template,
    );

    addAction(action);
  }

  void addTag(TagDbModel tag) {
    addAction(
      HomeQuickActionItem(
        id: 'tag:${tag.id}',
        label: tag.emoji == null ? tag.title : '${tag.emoji} ${tag.title}',
        subtitle: 'Tag',
        icon: SpIcons.tag,
        type: HomeQuickActionType.tag,
      ),
    );
  }

  void removeAction(HomeQuickActionItem action) {
    enabledActions.removeWhere((a) => a.id == action.id);
    _syncTimers.remove(action.id)?.cancel();
    _activatingIds.remove(action.id);
    // Re-insert the item into availableItems at its original position.
    final freshAvailable = defaultActions.where((a) => !isEnabled(a.id)).toList();
    for (int i = 0; i < freshAvailable.length; i++) {
      if (!availableItems.any((a) => a.id == freshAvailable[i].id)) {
        availableItems.insert(i, freshAvailable[i]);
        availableActionsListKey.currentState?.insertItem(i);
      }
    }
    notifyListeners();
  }

  void reorderActions(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = enabledActions.removeAt(oldIndex);
    enabledActions.insert(newIndex, item);
    notifyListeners();
  }

  void _markActionAsSyncing(String actionId) {
    _activatingIds.add(actionId);
    _syncTimers.remove(actionId)?.cancel();
    _syncTimers[actionId] = Timer(const Duration(seconds: 1), () {
      _syncTimers.remove(actionId);
      _activatingIds.remove(actionId);
      if (!disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    for (final timer in _syncTimers.values) {
      timer.cancel();
    }
    _syncTimers.clear();
    super.dispose();
  }
}
