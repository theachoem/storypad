part of 'edit_custom_reminder_view.dart';

class _EditCustomReminderContent extends StatelessWidget {
  const _EditCustomReminderContent(this.viewModel);

  final EditCustomReminderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('page.reminders.add_reminder')),
        actions: [
          if (!viewModel.isNew)
            SpPopupMenuButton(
              items: (context) => [
                SpPopMenuItem(
                  titleStyle: TextStyle(color: Theme.of(context).colorScheme.error),
                  leadingIconData: SpIcons.delete,
                  title: tr('button.delete'),
                  onPressed: () => viewModel.delete(context),
                ),
              ],
              builder: (callback) => IconButton(
                tooltip: tr('button.more_options'),
                icon: const Icon(SpIcons.moreVert),
                onPressed: callback,
              ),
            ),
        ],
      ),
      body: Form(
        key: viewModel.formKey,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            SpSectionTitle(title: tr('reminder.field.message')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildMessageField(context),
            ),
            const SizedBox(height: 8.0),
            ListTile(
              leading: const Icon(SpIcons.alarm),
              title: Text(tr('reminder.field.time')),
              trailing: Text(
                MaterialLocalizations.of(context).formatTimeOfDay(viewModel.time),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () => _pickTime(context),
            ),
            ReminderWeekdaysChips(weekdays: viewModel.weekdays, onChanged: viewModel.setWeekdays),
            const SizedBox(height: 12.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                reminderScheduleSummary(context, time: viewModel.time, weekdays: viewModel.weekdays),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(SpIcons.file),
              title: Text(tr('button.choose_template')),
              contentPadding: EdgeInsets.only(
                left: 16.0,
                right: viewModel.hasTemplate ? 8.0 : 16.0,
              ),
              subtitle: viewModel.hasTemplate && viewModel.templateName != null ? Text(viewModel.templateName!) : null,
              trailing: viewModel.hasTemplate
                  ? IconButton(icon: const Icon(SpIcons.clear), onPressed: viewModel.clearTemplate)
                  : const Icon(SpIcons.keyboardRight),
              onTap: () => viewModel.chooseTemplate(context),
            ),
            ListTile(
              leading: const Icon(SpIcons.tag),
              title: Text(tr('button.choose_tag')),
              contentPadding: EdgeInsets.only(
                left: 16.0,
                right: viewModel.tagIds.isNotEmpty ? 8.0 : 16.0,
              ),
              subtitle: viewModel.tagIds.isNotEmpty ? Text(viewModel.tagLabels(context)) : null,
              trailing: viewModel.tagIds.isNotEmpty
                  ? IconButton(icon: const Icon(SpIcons.clear), onPressed: viewModel.clearTags)
                  : const Icon(SpIcons.keyboardRight),
              onTap: () => viewModel.chooseTags(context),
            ),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(width: double.infinity, child: _buildSaveButton(context)),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    if (kIsCupertino) {
      return CupertinoButton.filled(
        disabledColor: Theme.of(context).disabledColor,
        sizeStyle: CupertinoButtonSize.medium,
        onPressed: () => viewModel.save(context),
        child: Text(tr('button.save')),
      );
    } else {
      return FilledButton(
        onPressed: () => viewModel.save(context),
        child: Text(tr('button.save')),
      );
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: viewModel.time);
    if (picked != null) viewModel.setTime(picked);
  }

  Widget _buildMessageField(BuildContext context) {
    return FormField<String>(
      initialValue: viewModel.messageController.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) => value?.trim().isNotEmpty == true ? null : tr('input.message.required'),
      builder: (state) {
        if (kIsCupertino) {
          return _buildCupertinoMessageField(context, state);
        } else {
          return _buildMaterialMessageField(context, state);
        }
      },
    );
  }

  Widget _buildMaterialMessageField(BuildContext context, FormFieldState<String> state) {
    return TextFormField(
      controller: viewModel.messageController,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: tr('reminder.field.message_hint'),
        border: const OutlineInputBorder(),
        errorText: state.errorText,
      ),
      maxLines: 2,
      onChanged: (value) => state.didChange(value),
    );
  }

  Widget _buildCupertinoMessageField(BuildContext context, FormFieldState<String> state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: viewModel.messageController,
          textCapitalization: TextCapitalization.sentences,
          placeholder: tr('reminder.field.message_hint'),
          maxLines: 2,
          decoration: BoxDecoration(
            border: Border.all(
              color: state.hasError ? CupertinoColors.destructiveRed : CupertinoColors.systemGrey3.resolveFrom(context),
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          onChanged: (value) => state.didChange(value),
        ),
        if (state.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 4.0),
            child: Text(
              state.errorText!,
              style: TextStyle(color: CupertinoColors.destructiveRed.resolveFrom(context), fontSize: 12.0),
            ),
          ),
      ],
    );
  }
}
