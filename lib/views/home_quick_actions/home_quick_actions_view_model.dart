import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/app_quick_action_object.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/app_quick_actions_service.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/views/home_quick_actions/home_quick_actions_view.dart';
import 'package:storypad/views/templates/templates_view.dart';
import 'package:storypad/widgets/sp_icons.dart';

class HomeQuickActionItem {
  const HomeQuickActionItem({
    required this.object,
    required this.icon,
  });

  final AppQuickActionObject object;
  final IconData icon;

  String get key => object.key;
  String get label => object.label;
  AppQuickActionType get type => object.type;
}

class HomeQuickActionsViewModel extends ChangeNotifier with DisposeAwareMixin {
  HomeQuickActionsViewModel({
    required this.params,
    required BuildContext context,
  }) {
    devicePreferencesProvider = context.read<DevicePreferencesProvider>();
    enabledActions = _actionsFromObjects(devicePreferencesProvider.preferences.homeQuickActions);
    availableItems.addAll(defaultActions.where((action) => !isEnabled(action.key)));
  }

  final HomeQuickActionsRoute params;

  late final DevicePreferencesProvider devicePreferencesProvider;
  late final int actionLimit = AppQuickActionsService.instance.maxActionCount;

  late List<HomeQuickActionItem>? enabledActions;

  final List<HomeQuickActionItem> defaultActions = [
    HomeQuickActionItem(
      object: AppQuickActionObject(
        label: tr('button.new_story'),
        type: AppQuickActionType.defaultAction,
        nativeIcon: AppDefaultQuickActionType.newStory.nativeIcon,
        defaultActionType: AppDefaultQuickActionType.newStory,
      ),
      icon: SpIcons.newStory,
    ),
    HomeQuickActionItem(
      object: AppQuickActionObject(
        label: tr('button.take_photo'),
        type: AppQuickActionType.defaultAction,
        nativeIcon: AppDefaultQuickActionType.takePhoto.nativeIcon,
        defaultActionType: AppDefaultQuickActionType.takePhoto,
      ),
      icon: SpIcons.camera,
    ),
    HomeQuickActionItem(
      object: AppQuickActionObject(
        label: tr('button.record_voice'),
        type: AppQuickActionType.defaultAction,
        nativeIcon: AppDefaultQuickActionType.recordVoice.nativeIcon,
        defaultActionType: AppDefaultQuickActionType.recordVoice,
      ),
      icon: SpIcons.voice,
    ),
  ];

  final GlobalKey<AnimatedListState> availableActionsListKey = GlobalKey<AnimatedListState>();

  // Tracks the default items currently visible in the AnimatedList.
  final List<HomeQuickActionItem> availableItems = [];
  final Set<String> _activatingIds = <String>{};
  final Map<String, Timer> _syncTimers = <String, Timer>{};

  Widget Function(HomeQuickActionItem, Animation<double>)? _availableTileBuilder;
  void setAvailableTileBuilder(Widget Function(HomeQuickActionItem, Animation<double>) builder) {
    _availableTileBuilder = builder;
  }

  bool isActivating(String actionId) => _activatingIds.contains(actionId);

  List<HomeQuickActionItem> get visibleEnabledActions => enabledActions ?? const [];
  bool get limitReached => enabledCount >= actionLimit;
  int get enabledCount => enabledActions?.length ?? 0;
  double get capacity => enabledCount / actionLimit;

  List<int> get selectedTagIds {
    return visibleEnabledActions
        .where((action) => action.type == AppQuickActionType.tag)
        .map((action) => action.object.tagId)
        .whereType<int>()
        .toList();
  }

  bool isEnabled(String key) {
    return visibleEnabledActions.any((action) => action.key == key);
  }

  void addAction(HomeQuickActionItem action) {
    if (limitReached || isEnabled(action.key)) return;
    final actions = enabledActions ??= [];
    final idx = availableItems.indexWhere((a) => a.key == action.key);
    if (idx != -1) {
      final removed = availableItems.removeAt(idx);
      availableActionsListKey.currentState?.removeItem(
        idx,
        (ctx, anim) => _availableTileBuilder?.call(removed, anim) ?? const SizedBox.shrink(),
      );
    }
    actions.add(action);
    AnalyticsService.instance.logQuickActionAdded(type: action.object.type.name);
    _saveActions();
    _markActionAsSyncing(action.key);
    notifyListeners();
  }

  void addTemplate(TemplatePickResult result) {
    final templateType = switch (result.type) {
      TemplatePickResultType.custom => AppQuickActionTemplateType.custom,
      TemplatePickResultType.gallery => AppQuickActionTemplateType.gallery,
    };

    addAction(
      HomeQuickActionItem(
        object: AppQuickActionObject(
          label: result.label,
          type: AppQuickActionType.template,
          nativeIcon: AppQuickActionObject.templateNativeIcon,
          templateReference: AppQuickActionTemplateReference(type: templateType, id: result.id),
        ),
        icon: SpIcons.file,
      ),
    );
  }

  void addTag(TagDbModel tag) {
    addAction(
      HomeQuickActionItem(
        object: AppQuickActionObject(
          label: tag.emoji == null ? tag.title : '${tag.emoji} ${tag.title}',
          type: AppQuickActionType.tag,
          nativeIcon: AppQuickActionObject.tagNativeIcon,
          tagId: tag.id,
        ),
        icon: SpIcons.tag,
      ),
    );
  }

  void removeAction(HomeQuickActionItem action) {
    enabledActions?.removeWhere((a) => a.key == action.key);
    _syncTimers.remove(action.key)?.cancel();
    _activatingIds.remove(action.key);

    // Re-insert the item into availableItems at its original position.
    final freshAvailable = defaultActions.where((a) => !isEnabled(a.key)).toList();

    for (int i = 0; i < freshAvailable.length; i++) {
      if (!availableItems.any((a) => a.key == freshAvailable[i].key)) {
        availableItems.insert(i, freshAvailable[i]);
        availableActionsListKey.currentState?.insertItem(i);
      }
    }

    _saveActions();
    notifyListeners();
  }

  // [newIndex] already accounts for the removed item (ReorderableListView's `onReorderItem`).
  void reorderActions(int oldIndex, int newIndex) {
    final actions = enabledActions;
    if (actions == null) return;

    final item = actions.removeAt(oldIndex);
    actions.insert(newIndex, item);
    _saveActions();
    notifyListeners();
  }

  List<HomeQuickActionItem>? _actionsFromObjects(List<AppQuickActionObject>? objects) {
    if (objects == null) return null;
    return objects
        .where((object) => object.key.isNotEmpty)
        .map((object) => HomeQuickActionItem(object: object, icon: _iconFor(object)))
        .toList();
  }

  IconData _iconFor(AppQuickActionObject object) {
    return switch (object.type) {
      AppQuickActionType.defaultAction =>
        defaultActions.where((a) => a.object.defaultActionType == object.defaultActionType).firstOrNull?.icon ??
            SpIcons.question,
      AppQuickActionType.template => SpIcons.file,
      AppQuickActionType.tag => SpIcons.tag,
    };
  }

  void _saveActions() {
    devicePreferencesProvider.setHomeQuickActions(
      visibleEnabledActions.map((action) => action.object).toList(),
    );
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
