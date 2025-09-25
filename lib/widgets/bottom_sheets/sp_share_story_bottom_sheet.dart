import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/feeling_object.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/reddit_opener_service.dart';
import 'package:storypad/core/services/remote_config/remote_config_service.dart';
import 'package:storypad/core/services/story_plain_text_exporter.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/views/stories/local_widgets/base_story_view_model.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_markdown_body.dart';

class SpShareStoryBottomSheet extends BaseBottomSheet {
  @override
  bool get fullScreen => true;

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
    if (kIsCupertino) {
      return _ShareStoryBottomSheet(
        story: story,
        draftContent: draftContent,
        pagesManager: pagesManager,
        bottomPadding: bottomPadding,
      );
    } else {
      double maxChildSize = 1 - View.of(context).viewPadding.top / MediaQuery.of(context).size.height;
      return DraggableScrollableSheet(
        expand: false,
        maxChildSize: maxChildSize,
        initialChildSize: maxChildSize,
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: _ShareStoryBottomSheet(
              story: story,
              draftContent: draftContent,
              pagesManager: pagesManager,
              bottomPadding: bottomPadding,
            ),
          );
        },
      );
    }
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
      timeFormat: context.read<DevicePreferencesProvider>().preferences.timeFormat,
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: CupertinoSheetRoute.hasParentSheet(context) ? 72 : null,
        centerTitle: true,
        leading: CupertinoSheetRoute.hasParentSheet(context) ? const SizedBox.shrink() : null,
        automaticallyImplyLeading: false,
        actions: [
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context))
        ],
        title: buildOptions(context),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom + 12,
          left: 16.0,
          right: 16.0,
        ),
        child: FilledButton.icon(
          icon: const Icon(SpIcons.share),
          label: Text(tr("button.share")),
          // TODO: on ios it does not show share logo well.
          onPressed: () => share(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                textAlignVertical: const TextAlignVertical(y: -1.0),
                expands: true,
                controller: controller,
                maxLength: null,
                maxLines: null,
                decoration: const InputDecoration(hintText: "..."),
                onSubmitted: (value) => share(),
              ),
            ),
            if (kIAPEnabled) buildShareToRedditCard(context),
          ],
        ),
      ),
    );
  }

  Widget buildShareToRedditCard(BuildContext context) {
    return Visibility(
      visible: MediaQuery.of(context).viewInsets.bottom == 0, // keyboard closed
      child: Container(
        margin: const EdgeInsets.only(top: 16.0),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 12.0, right: 6.0, top: 6.0, bottom: 8.0),
          leading: Icon(Icons.reddit_outlined, size: 32.0, color: Theme.of(context).colorScheme.primary),
          trailing: IconButton(
            onPressed: () => submitRedditPost(),
            icon: const Icon(SpIcons.share),
          ),
          tileColor: Theme.of(context).colorScheme.readOnly.surface1,
          shape: RoundedSuperellipseBorder(
            side: BorderSide(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: SpMarkdownBody(
            body: "### ${tr(
              'list_tile.share_to_reddit.title',
              namedArgs: {'REDDIT_LINK': '[r/StoryPad](${RemoteConfigService.redditUrl.get()})'},
            )}",
          ),
          subtitle: SpMarkdownBody(
            body: tr('list_tile.share_to_reddit.subtitle'),
          ),
        ),
      ),
    );
  }

  void submitRedditPost() {
    // split the text first like except empty lines consider a title, then body is rest
    final lines = controller.text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

    String? title = lines.isNotEmpty ? lines.first : null;
    String body = lines.length > 1 ? lines.skip(1).join('\n') : '';

    RedditOpenerService.submitPost(
      title: title,
      body: body,
      context: context,
    );
  }

  Widget buildOptions(BuildContext context) {
    return Row(
      spacing: 4.0,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }

  Future<void> share() async {
    AnalyticsService.instance.logShareStory(option: option.name);
    SharePlus.instance.share(ShareParams(text: controller.text.trim()));
  }
}
