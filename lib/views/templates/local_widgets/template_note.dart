import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/widgets/sp_icons.dart';

class TemplateNote extends StatelessWidget {
  const TemplateNote({
    super.key,
    required this.note,
  });

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Theme.of(context).colorScheme.readOnly.surface2,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(SpIcons.lightBulb, size: 16.0),
            ),
            TextSpan(text: ' $note '),
          ],
        ),
        style: TextTheme.of(context).bodyMedium,
      ),
    );
  }
}
