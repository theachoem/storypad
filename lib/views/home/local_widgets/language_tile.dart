import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/locale_constants.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/views/languages/languages_view.dart';

class LanguageTile extends StatelessWidget {
  const LanguageTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          text: "${tr("page.language.title")} ",
          children: [
            WidgetSpan(
              child: Material(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                color: ColorScheme.of(context).bootstrap.success.color,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.textScalerOf(context).scale(6),
                    vertical: MediaQuery.textScalerOf(context).scale(1),
                  ),
                  child: Text(
                    tr('general.beta'),
                    style: TextTheme.of(context)
                        .labelMedium
                        ?.copyWith(color: ColorScheme.of(context).bootstrap.success.onColor),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
      subtitle: Text(kNativeLanguageNames[context.locale.toLanguageTag()]!),
      onTap: () => LanguagesRoute().push(context),
    );
  }
}
