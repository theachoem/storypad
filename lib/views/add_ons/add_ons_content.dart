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

  static List<String> _demoImagesFor(AddOnType addOn) {
    switch (addOn) {
      case .relax_sounds:
        return SpDemoImagesSheet.relaxSoundDemoImages;
      case .period_calendar:
        return SpDemoImagesSheet.periodCalendarDemoImages;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read-only: this tile rebuilds when AddOnsViewModel notifies (scoped to
    // add-on changes via addListenerForAddOnChanges), not by watching
    // DevicePreferencesProvider directly — see _RemindersContent for the same pattern.
    final provider = context.read<DevicePreferencesProvider>();

    bool enabled =
        (provider.enableRelaxSounds && addOn == AddOnType.relax_sounds) ||
        (provider.enablePeriodCalendar(context) && addOn == AddOnType.period_calendar);

    // The switch reflects the true enabled state but doesn't toggle directly —
    // tapping it (like tapping the tile) opens the sheet, where the real
    // switch lives. Keeps this consistent with the reminders list tiles.
    void openSheet() {
      SpDemoImagesSheet(
        demoImages: _demoImagesFor(addOn),
        header: _AddOnSwitchTile(addOn: addOn),
      ).show(context: context);
    }

    return ListTile(
      onTap: openSheet,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: SpSettingIconBadge(
        weekday: addOn.weekdayColor,
        icon: addOn.icon,
      ),
      title: _AddOnTitle(addOn: addOn),
      subtitle: Text(addOn.description),
      trailing: Switch.adaptive(value: enabled, onChanged: (_) => openSheet()),
    );
  }
}

/// The sheet's [SpDemoImagesSheet.header]: the real switch that actually
/// toggles the add-on. Tracks its own local state instead of watching
/// [DevicePreferencesProvider] — toggleAddOn only fires its scoped 'add_on'
/// listeners, not ChangeNotifier's notifyListeners(), so watching the
/// provider here would never rebuild this switch (see reminders_content.dart
/// for the same scoped-listener reasoning).
class _AddOnSwitchTile extends StatefulWidget {
  const _AddOnSwitchTile({required this.addOn});

  final AddOnType addOn;

  @override
  State<_AddOnSwitchTile> createState() => _AddOnSwitchTileState();
}

class _AddOnSwitchTileState extends State<_AddOnSwitchTile> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DevicePreferencesProvider>();
    _enabled =
        (provider.enableRelaxSounds && widget.addOn == AddOnType.relax_sounds) ||
        (provider.enablePeriodCalendar(context) && widget.addOn == AddOnType.period_calendar);
  }

  void _setEnabled(bool value) {
    context.read<DevicePreferencesProvider>().toggleAddOn(widget.addOn, value);
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
      value: _enabled,
      secondary: SpSettingIconBadge(weekday: widget.addOn.weekdayColor, icon: widget.addOn.icon),
      title: _AddOnTitle(addOn: widget.addOn),
      subtitle: Text(widget.addOn.description),
      onChanged: _setEnabled,
    );
  }
}

class _AddOnTitle extends StatelessWidget {
  const _AddOnTitle({required this.addOn});

  final AddOnType addOn;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
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
    );
  }
}
