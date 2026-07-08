import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/reminder_object.dart';
import 'package:storypad/core/services/gallery_template_service.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/views/templates/templates_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_tags_picker_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_templates_picker_sheet.dart';

class EditCustomReminderViewModel extends ChangeNotifier with DisposeAwareMixin {
  EditCustomReminderViewModel({
    required this.reminder,
    required this.isNew,
  }) : messageController = TextEditingController(text: reminder.message ?? '') {
    time = reminder.timeOfDay;
    // Every day is stored as an empty set — show it as all 7 chips checked
    // so the user can see the current schedule before pruning it down.
    weekdays = reminder.weekdays.isEmpty ? ReminderObject.allWeekdays.toSet() : reminder.weekdays.toSet();
    templateId = reminder.templateId;
    galleryTemplateId = reminder.galleryTemplateId;
    tagIds = List<int>.from(reminder.tagIds ?? const []);

    // Editing an existing reminder that already has a saved template — its
    // display name wasn't cached, so resolve it once on load.
    if (hasTemplate) _loadTemplateName();
  }

  /// The reminder being edited. Its `enabled` flag isn't user-editable on this
  /// page (only the reminders list toggle changes it) — preserved as-is on save.
  final ReminderObject reminder;

  /// True while creating a brand-new reminder — nothing's persisted yet, so
  /// Delete isn't offered.
  final bool isNew;

  final formKey = GlobalKey<FormState>();

  /// Backs the adaptive message field (Material/Cupertino share it) so typing
  /// doesn't need a `notifyListeners()` round-trip through the view model.
  final TextEditingController messageController;

  late TimeOfDay time;
  late Set<int> weekdays;
  late int? templateId;
  late String? galleryTemplateId;
  late List<int> tagIds;

  /// Display name for the selected template, if any. Null while unset or
  /// still being resolved (see constructor).
  String? templateName;

  bool get hasTemplate => templateId != null || galleryTemplateId != null;

  void setTime(TimeOfDay value) {
    time = value;
    notifyListeners();
  }

  void setWeekdays(Set<int> value) {
    weekdays = value;
    notifyListeners();
  }

  Future<void> chooseTemplate(BuildContext context) async {
    final result = await const SpTemplatesPickerSheet().show<TemplatePickResult>(context: context);
    if (result == null) return;

    switch (result.type) {
      case TemplatePickResultType.custom:
        templateId = result.customTemplate?.id;
        galleryTemplateId = null;
        break;
      case TemplatePickResultType.gallery:
        galleryTemplateId = result.galleryTemplate?.id;
        templateId = null;
        break;
    }
    templateName = result.label;
    notifyListeners();
  }

  void clearTemplate() {
    templateId = null;
    galleryTemplateId = null;
    templateName = null;
    notifyListeners();
  }

  Future<void> _loadTemplateName() async {
    if (templateId != null) {
      final template = await TemplateDbModel.db.find(templateId!);
      templateName = template?.name ?? tr('general.na');
    } else if (galleryTemplateId != null) {
      final templatesByCategory = await GalleryTemplateService.loadTemplates();
      for (final templates in templatesByCategory.values) {
        for (final template in templates) {
          if (template.id == galleryTemplateId) {
            templateName = template.name;
            break;
          }
        }
      }
    }
    notifyListeners();
  }

  Future<void> chooseTags(BuildContext context) async {
    final result = await SpTagsPickerSheet(selectedTagIds: tagIds).show<List<TagDbModel>>(context: context);
    if (result == null) return;

    tagIds = result.map((e) => e.id).toList();
    notifyListeners();
  }

  void clearTags() {
    tagIds = [];
    notifyListeners();
  }

  String tagLabels(BuildContext context) {
    final allTags = context.read<TagsProvider>().allTags?.items ?? [];
    final titles = tagIds.map((id) => allTags.where((t) => t.id == id).firstOrNull?.title).whereType<String>().toList();
    return titles.join(', ');
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> save(BuildContext context) async {
    if (formKey.currentState?.validate() != true) return;
    final trimmedMessage = messageController.text.trim();

    final updated = reminder.copyWith(
      hour: time.hour,
      minute: time.minute,
      weekdays: ReminderObject.normalizeWeekdays(weekdays),
      message: trimmedMessage.isNotEmpty ? trimmedMessage : null,
      templateId: templateId,
      galleryTemplateId: galleryTemplateId,
      tagIds: tagIds.isNotEmpty ? tagIds : null,
    );

    await context.read<DevicePreferencesProvider>().upsertReminder(updated);
    if (context.mounted) Navigator.of(context).pop(true);
  }

  Future<void> delete(BuildContext context) async {
    await context.read<DevicePreferencesProvider>().deleteReminder(reminder.id);
    if (context.mounted) Navigator.of(context).pop(true);
  }
}
