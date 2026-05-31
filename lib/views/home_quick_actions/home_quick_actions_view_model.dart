import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/app_quick_action_object.dart';
import 'package:storypad/core/services/app_quick_actions_service.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/home_quick_actions/home_quick_actions_view.dart';
import 'package:storypad/views/templates/templates_view.dart';
import 'package:storypad/widgets/sp_icons.dart';

class HomeQuickActionItem {
  const HomeQuickActionItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.type,
  });

  final String id;
  final String label;
  final IconData icon;
  final AppQuickActionType type;
}

class HomeQuickActionsViewModel extends ChangeNotifier with DisposeAwareMixin {
  HomeQuickActionsViewModel({
    required this.params,
    required BuildContext context,
  }) {
    isProUser = context.read<InAppPurchaseProvider>().isProUser;
    devicePreferencesProvider = context.read<DevicePreferencesProvider>();
    enabledActions = _actionsFromObjects(devicePreferencesProvider.preferences.homeQuickActions);
    availableItems.addAll(defaultActions.where((action) => !isEnabled(action.id)));
  }

  final HomeQuickActionsRoute params;

  late final bool isProUser;
  late final DevicePreferencesProvider devicePreferencesProvider;

  late final int actionLimit = AppQuickActionsService.instance.maxActionCount;

  late List<HomeQuickActionItem>? enabledActions;

  final List<HomeQuickActionItem> defaultActions = [
    HomeQuickActionItem(
      id: AppDefaultQuickActionType.newStory.id,
      label: tr('button.new_story'),
      icon: SpIcons.newStory,
      type: AppQuickActionType.defaultAction,
    ),
    HomeQuickActionItem(
      id: AppDefaultQuickActionType.takePhoto.id,
      label: tr('button.take_photo'),
      icon: SpIcons.camera,
      type: AppQuickActionType.defaultAction,
    ),
    HomeQuickActionItem(
      id: AppDefaultQuickActionType.recordVoice.id,
      label: tr('button.record_voice'),
      icon: SpIcons.voice,
      type: AppQuickActionType.defaultAction,
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
        .map((action) => int.tryParse(action.id.replaceFirst('tag:', '')))
        .whereType<int>()
        .toList();
  }

  bool isEnabled(String id) {
    return visibleEnabledActions.any((action) => action.id == id);
  }

  void addAction(HomeQuickActionItem action) {
    if (limitReached || isEnabled(action.id)) return;
    final actions = enabledActions ??= [];
    final idx = availableItems.indexWhere((a) => a.id == action.id);
    if (idx != -1) {
      final removed = availableItems.removeAt(idx);
      availableActionsListKey.currentState?.removeItem(
        idx,
        (ctx, anim) => _availableTileBuilder?.call(removed, anim) ?? const SizedBox.shrink(),
      );
    }
    actions.add(action);
    _saveActions();
    _markActionAsSyncing(action.id);
    notifyListeners();
  }

  void addTemplate(TemplatePickResult result) {
    final action = HomeQuickActionItem(
      id: AppQuickActionObject.templateId(
        type: switch (result.type) {
          TemplatePickResultType.custom => AppQuickActionTemplateType.custom,
          TemplatePickResultType.gallery => AppQuickActionTemplateType.gallery,
        },
        id: result.id,
      ),
      label: result.label,
      icon: SpIcons.file,
      type: AppQuickActionType.template,
    );

    addAction(action);
  }

  void addTag(TagDbModel tag) {
    addAction(
      HomeQuickActionItem(
        id: AppQuickActionObject.tagActionId(tag.id),
        label: tag.emoji == null ? tag.title : '${tag.emoji} ${tag.title}',
        icon: SpIcons.tag,
        type: AppQuickActionType.tag,
      ),
    );
  }

  void removeAction(HomeQuickActionItem action) {
    enabledActions?.removeWhere((a) => a.id == action.id);
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
    _saveActions();
    notifyListeners();
  }

  void reorderActions(int oldIndex, int newIndex) {
    final actions = enabledActions;
    if (actions == null) return;

    if (newIndex > oldIndex) newIndex--;
    final item = actions.removeAt(oldIndex);
    actions.insert(newIndex, item);
    _saveActions();
    notifyListeners();
  }

  List<HomeQuickActionItem>? _actionsFromObjects(List<AppQuickActionObject>? objects) {
    if (objects == null) return null;

    return objects
        .map(
          (object) => HomeQuickActionItem(
            id: object.id,
            label: object.label,
            icon: _iconFor(object),
            type: object.type,
          ),
        )
        .toList();
  }

  IconData _iconFor(AppQuickActionObject object) {
    return switch (object.type) {
      AppQuickActionType.defaultAction => defaultActions.firstWhere((action) => action.id == object.id).icon,
      AppQuickActionType.template => SpIcons.file,
      AppQuickActionType.tag => SpIcons.tag,
    };
  }

  void _saveActions() {
    devicePreferencesProvider.setHomeQuickActions(
      visibleEnabledActions
          .map(
            (action) => AppQuickActionObject(
              id: action.id,
              label: action.label,
              type: action.type,
              nativeIcon: AppQuickActionObject.nativeIconFor(
                type: action.type,
                id: action.id,
              ),
            ),
          )
          .toList(),
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
