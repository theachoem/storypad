part of 'add_ons_view.dart';

class _AddOnsContent extends StatelessWidget {
  const _AddOnsContent(this.viewModel);

  final AddOnsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorScheme.of(context).readOnly.surface1,
        title: Text(tr("page.add_ons.title")),
      ),
      body: ListView.separated(
        itemCount: AddOnType.values.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final addOn = AddOnType.values[index];
          return _AddOnTile(addOn: addOn);
        },
      ),
    );
  }
}

class _AddOnTile extends StatelessWidget {
  const _AddOnTile({
    required this.addOn,
  });

  final AddOnType addOn;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DevicePreferencesProvider>();

    bool enabled =
        (provider.enableRelaxSounds && addOn == AddOnType.relax_sounds) ||
        (provider.enablePeriodCalendar(context) && addOn == AddOnType.period_calendar);

    return ListTile(
      onTap: () {
        switch (addOn) {
          case .relax_sounds:
            SpDemoImagesSheet.relaxSoundDemo().show(context: context);
            break;
          case .period_calendar:
            SpDemoImagesSheet.periodCalendarDemo().show(context: context);
            break;
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: SpSettingIconBadge(
        weekday: addOn.weekdayColor,
        icon: addOn.icon,
      ),
      title: Text.rich(
        TextSpan(
          text: addOn.displayName,
          style: Theme.of(context).textTheme.bodyLarge,
          children: [
            if (addOn.designForFemale)
              const WidgetSpan(
                child: Icon(Icons.female_outlined, size: 22.0),
                alignment: PlaceholderAlignment.middle,
              ),
          ],
        ),
      ),
      subtitle: Text(addOn.description),
      trailing: Switch.adaptive(
        value: enabled,
        onChanged: (bool value) => provider.toggleAddOn(addOn, value),
      ),
    );
  }
}
