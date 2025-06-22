part of 'sp_pages_toolbar.dart';

class _TitleToolbar extends StatelessWidget {
  const _TitleToolbar({
    required this.preferences,
    required this.onThemeChanged,
  });

  final StoryPreferencesDbModel preferences;
  final void Function(StoryPreferencesDbModel preferences) onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final fontWeight = preferences.titleFontWeight ?? kTitleDefaultFontWeight;

    final fontFamily = preferences.titleFontFamily ??
        preferences.fontFamily ??
        context.read<DevicePreferencesProvider>().preferences.fontFamily;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8.0),
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildFontFamilyButton(fontFamily, fontWeight, context),
              const SizedBox(width: 4.0),
              buildFontWeightButton(fontWeight, context),
              IconButton.outlined(
                tooltip: tr('button.reset'),
                color: ColorScheme.of(context).primary,
                style: IconButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                icon: const Icon(SpIcons.refresh),
                onPressed: preferences.titleReseted
                    ? null
                    : () => onThemeChanged(preferences.copyWith(titleFontFamily: null, titleFontWeightIndex: null)),
              )
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget buildFontWeightButton(FontWeight currentFontWeight, BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(SpIcons.fontWeight),
      label: Text(FontWeightTile.getFontWeightTitle(currentFontWeight)),
      onPressed: () {
        SpFontWeightSheet(
          showDefaultLabel: false,
          defaultFontWeight: kTitleDefaultFontWeight,
          fontWeight: currentFontWeight,
          onChanged: (fontWeight) => onThemeChanged(preferences.copyWith(titleFontWeightIndex: fontWeight.index)),
        ).show(context: context);
      },
    );
  }

  Widget buildFontFamilyButton(String fontFamily, FontWeight fontWeight, BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(SpIcons.font),
      label: Text(fontFamily),
      onPressed: () {
        SpFontsSheet(
          currentFontFamily: fontFamily,
          currentFontWeight: fontWeight,
          onChanged: (fontFamily) => onThemeChanged(preferences.copyWith(titleFontFamily: fontFamily)),
        ).show(context: context);
      },
    );
  }
}
