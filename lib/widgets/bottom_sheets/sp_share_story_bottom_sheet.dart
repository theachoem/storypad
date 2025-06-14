import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/objects/feeling_object.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/core/services/story_plain_text_exporter.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpShareStoryBottomSheet extends BaseBottomSheet {
  @override
  bool get fullScreen => false;

  final StoryDbModel story;
  final StoryContentDbModel draftContent;
  final StoryPagesManagerInfo pagesManager;

  SpShareStoryBottomSheet({
    required this.story,
    required this.draftContent,
    required this.pagesManager,
  });

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return _ShareStoryBottomSheet(
      story: story,
      draftContent: draftContent,
      pagesManager: pagesManager,
      bottomPadding: bottomPadding,
    );
  }
}

class _ShareStoryBottomSheet extends StatefulWidget {
  const _ShareStoryBottomSheet({
    required this.story,
    required this.draftContent,
    required this.pagesManager,
    required this.bottomPadding,
  });

  final StoryDbModel story;
  final StoryContentDbModel draftContent;
  final StoryPagesManagerInfo pagesManager;
  final double bottomPadding;

  @override
  State<_ShareStoryBottomSheet> createState() => _ShareStoryBottomSheetState();
}

enum _ShareOption {
  txt,
  markdown,
}

class _ShareStoryBottomSheetState extends State<_ShareStoryBottomSheet> {
  late final TextEditingController controller = TextEditingController(text: getShareText(context));

  _ShareOption option = _ShareOption.txt;

  String getShareText(BuildContext context) {
    final tags =
        context.read<TagsProvider>().tags?.items.where((e) => widget.story.validTags?.contains(e.id) == true).toList();

    final feeling = FeelingObject.feelingsByKey[widget.story.feeling];

    List<StoryPageObject> pages = List.generate(widget.draftContent.richPages?.length ?? 0, (index) {
      final page = widget.draftContent.richPages![index];
      return widget.pagesManager.pagesMap[page.id];
    }).toList().whereType<StoryPageObject>().toList();

    return StoryPlainTextExporter(
      pages: pages,
      displayPathDate: widget.story.displayPathDate,
      tags: tags ?? [],
      locale: context.locale,
      feeling: feeling?.translation(context),
      markdown: option == _ShareOption.markdown,
    ).export();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 4.0,
            runSpacing: 4.0,
            children: [
              ChoiceChip(
                showCheckmark: false,
                avatar: Icon(MdiIcons.text),
                label: const Text("Text"),
                selected: option == _ShareOption.txt,
                onSelected: (value) {
                  option = _ShareOption.txt;
                  controller.text = getShareText(context);
                  setState(() {});
                },
              ),
              ChoiceChip(
                showCheckmark: false,
                avatar: Icon(MdiIcons.languageMarkdown),
                label: const Text("Markdown"),
                selected: option == _ShareOption.markdown,
                onSelected: (value) {
                  option = _ShareOption.markdown;
                  controller.text = getShareText(context);
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          TextField(
            controller: controller,
            maxLength: null,
            maxLines: 18,
            decoration: const InputDecoration(hintText: "..."),
            onSubmitted: (value) => SharePlus.instance.share(ShareParams(text: controller.text.trim())),
          ),
          const SizedBox(height: 12.0),
          FilledButton.icon(
            icon: const Icon(SpIcons.share),
            label: Text(tr("button.share")),
            // TODO: on ios it does not show share logo well.
            onPressed: () => SharePlus.instance.share(ShareParams(text: controller.text.trim())),
          ),
          SizedBox(height: widget.bottomPadding)
        ],
      ),
    );
  }
}
