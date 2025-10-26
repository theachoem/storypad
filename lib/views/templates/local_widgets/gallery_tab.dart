import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/gallery_template_category_object.dart';
import 'package:storypad/core/objects/gallery_template_object.dart';
import 'package:storypad/core/services/gallery_template_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/views/templates/gallery/show/show_template_gallery_view.dart';
import 'package:storypad/views/templates/templates_view.dart';
import 'package:storypad/widgets/sp_firestore_storage_downloader_builder.dart';
import 'package:storypad/widgets/sp_gradient_loading.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_snap_scroll_physics.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

part 'license_text.dart';
part 'gallery_template_card.dart';

class GalleryTab extends StatefulWidget {
  const GalleryTab({
    super.key,
    required this.params,
    required this.appBarActionsLoaderCallback,
  });

  final TemplatesRoute params;
  final void Function(List<IconButton> icons)? appBarActionsLoaderCallback;

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> {
  @override
  void initState() {
    super.initState();
    load();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.appBarActionsLoaderCallback?.call([]);
    });
  }

  Map<GalleryTemplateCategoryObject, List<GalleryTemplateObject>>? templates;

  Future<void> load() async {
    final loadedTemplates = await GalleryTemplateService.loadTemplates();
    templates = loadedTemplates;
    setState(() {});
  }

  Future<void> openTemplate(BuildContext context, GalleryTemplateObject template) async {
    final result = await ShowTemplateGalleryRoute(
      galleryTemplate: template,
    ).push(context);

    if (context.mounted && result is StoryDbModel) {
      Navigator.maybePop(context, result);
    } else {
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (templates == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return Scaffold(
      body: ListView.separated(
        itemCount: templates!.keys.length + 1,
        padding: EdgeInsets.only(
          top: 16.0,
          bottom: 16.0 + MediaQuery.of(context).padding.bottom,
        ),
        separatorBuilder: (context, index) => const SizedBox(height: 24),
        itemBuilder: (BuildContext context, int index) {
          if (index == templates?.length) {
            return const _LicenseText();
          }

          GalleryTemplateCategoryObject category = templates!.keys.elementAt(index);
          List<GalleryTemplateObject> templatesInCategory = templates!.values.elementAt(index);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text.rich(
                  TextSpan(
                    text: category.name,
                    style: TextTheme.of(context).titleMedium,
                    children: [
                      if (context.locale.languageCode != 'en')
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            margin: const EdgeInsets.only(left: 6.0),
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              color: ColorScheme.of(context).readOnly.surface2,
                            ),
                            child: Text(
                              'EN',
                              style: TextTheme.of(context).labelMedium,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  category.description,
                  style: TextTheme.of(context).bodyMedium,
                ),
              ),
              const SizedBox(height: 12.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                physics: SpSnapScrollPhysics(
                  itemWidthGetter: (metrics) {
                    return 170 + 16.0;
                  },
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < templatesInCategory.length; i++)
                        Container(
                          width: 170,
                          margin: EdgeInsets.only(
                            right: i < templatesInCategory.length - 1 ? 12.0 : 0.0,
                          ),
                          child: _GalleryTemplateCard(
                            template: templatesInCategory[i],
                            onTap: () => openTemplate(context, templatesInCategory[i]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
