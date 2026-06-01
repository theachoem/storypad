# Home Quick Actions Implementation

This document covers the first core implementation for Home Quick Actions after the UX/UI screen.

## Storage

Configured actions are stored on `DevicePreferencesObject.homeQuickActions` as `List<AppQuickActionObject>?`.

- `null` means the user has not intentionally configured Home Quick Actions yet.
- An empty list means the user configured the feature and removed every action.
- A non-empty list is the exact order shown in the native home-screen quick actions menu.

This keeps first install and migrated users untouched: the app does not initialize the native quick-actions plugin just to create defaults.

## Model

`AppQuickActionObject` stores the stable native action payload:

- `id`: the shortcut type passed to `quick_actions` and later used for routing.
- `label`: native menu title.
- `subtitle`: optional native menu subtitle.
- `type`: `defaultAction`, `template`, or `tag`.
- `nativeIcon`: optional native asset/drawable resource name for a later platform icon pass.

UI-only Flutter `IconData` is not persisted. The Home Quick Actions view model maps stored action type/id back to `SpIcons` for the preview.

Default quick actions use `AppDefaultQuickActionType`, and template ids use `AppQuickActionTemplateType`. Launch handling switches over these enums without a default branch so future enum values require an explicit handling decision.

## Service

`AppQuickActionsService` is the only layer that talks to the `quick_actions` package.

- `setActions(actions)` publishes the current list via `QuickActions.setShortcutItems`.
- `clearActions()` removes native shortcuts by publishing an empty list.
- `initialize(navigatorKey: ...)` registers the native launch callback and dispatches supported actions through the root navigator.
- `maxActionCount` owns platform capacity: both iOS and Android support 4 actions (`iosMaxActionCount = 4`, `androidMaxActionCount = 4`); other platforms return 0.
- The service is guarded by a `supported` getter (`Platform.isIOS || Platform.isAndroid`); all public methods return early when `supported` is false, so desktop builds skip the plugin entirely.

## Provider Flow

`DevicePreferencesProvider.setHomeQuickActions` is the write path:

1. Update `DevicePreferencesObject.homeQuickActions`.
2. Persist the preferences through `DevicePreferencesStorage`.
3. Publish the same list to `AppQuickActionsService`.

`setHomeQuickActions` intentionally does **not** call `notifyListeners` — it only syncs with the system. The view model owns its own state and updates the UI directly.

Preference reset clears native shortcuts as well.

## Home Quick Actions Screen Flow

The screen starts from `preferences.homeQuickActions`.

- If preferences are `null`, `enabledActions` stays `null` and all default actions remain available to add.
- Capacity is read from `AppQuickActionsService.maxActionCount` so iOS and Android can differ.
- Adding the first item creates the list, persists it, and publishes native shortcuts.
- Removing or reordering actions persists and republishes immediately.
- Template and tag rows keep using the existing picker sheets and become persisted `template:*` and `tag:*` action ids.

## Launch Handling

When the native plugin reports a clicked action id, `AppQuickActionsService` resolves that id against persisted device preferences and handles all currently supported action types:

- Default: New Story, Take Photo, Record Voice.
- Template: opens the editor from a saved custom template or gallery template.
- Tag: opens the tag story list.

If the action id is no longer stored, points to deleted content, or cannot be parsed, the launch is ignored.

## Native Icon Guide

For native home quick action icon workflow (Android and iOS), see:

- [UI Home Quick Action Icons Guide](../../ui/home-quick-action-icons.md)

## Follow-up Phases

- Add native icon resources and populate `nativeIcon` for default actions.
- Decide whether to republish stored shortcuts on app startup after app upgrades or localization changes.
