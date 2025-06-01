import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/views/tags/show/show_tag_view.dart';

class TemplateTagLabels extends StatelessWidget {
  const TemplateTagLabels({
    super.key,
    required this.template,
    this.margin = EdgeInsets.zero,
  });

  final TemplateDbModel template;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Consumer<TagsProvider>(builder: (context, provider, _) {
      List<TagDbModel> tags = [];

      for (TagDbModel tag in provider.tags?.items ?? []) {
        if (template.tags?.contains(tag.id) == true) {
          tags.add(tag);
        }
      }

      if (tags.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: margin,
        child: Wrap(
          spacing: MediaQuery.textScalerOf(context).scale(4),
          runSpacing: MediaQuery.textScalerOf(context).scale(4),
          children: tags.map((tag) {
            return Material(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
              color: (AppTheme.isDarkMode(context) ? Colors.white : Colors.black).withValues(alpha: 0.06),
              child: InkWell(
                borderRadius: BorderRadius.circular(4.0),
                onTap: () => ShowTagRoute(tag: tag, storyViewOnly: true).push(context),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.textScalerOf(context).scale(7),
                    vertical: MediaQuery.textScalerOf(context).scale(1),
                  ),
                  child: Text(
                    tag.title,
                    style: TextTheme.of(context).labelMedium,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}
