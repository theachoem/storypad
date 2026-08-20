import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/views/templates/edit/edit_template_view.dart';
import 'package:storypad/views/templates/local_widgets/template_tag_labels.dart';
import 'package:storypad/views/templates/show/show_template_view.dart';
import 'package:storypad/views/templates/templates_view.dart';
import 'package:storypad/widgets/sp_fab_location.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_scroll_configuration.dart';

part 'template_tile.dart';
part 'empty_body.dart';

class TemplatesTab extends StatefulWidget {
  const TemplatesTab({
    super.key,
    required this.params,
  });

  final TemplatesRoute params;

  @override
  State<TemplatesTab> createState() => _TemplatesTabState();
}

class _TemplatesTabState extends State<TemplatesTab> {
  TemplatesRoute get params => widget.params;
  CollectionDbModel<TemplateDbModel>? templates;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    templates = await TemplateDbModel.db.where(filters: {'archived': params.viewingArchives});
    setState(() {});
  }

  Future<void> goToNewPage(BuildContext context) async {
    await EditTemplateRoute(flowType: .create).push(context);
    await load();
  }

  void goToArchivesPage(BuildContext context) async {
    await TemplatesRoute(
      viewingArchives: true,
      initialYear: params.initialYear,
      initialMonth: params.initialMonth,
      initialDay: params.initialDay,
    ).push(context);

    await load();
  }

  void goToShowPage(BuildContext context, TemplateDbModel template) async {
    if (params.pickMode) {
      Navigator.maybePop(context, TemplatePickResult.custom(template));
      return;
    }

    final result = await ShowTemplateRoute(
      template: template,
      initialYear: params.initialYear,
      initialMonth: params.initialMonth,
      initialDay: params.initialDay,
    ).push(context);

    if (context.mounted && result is StoryDbModel) {
      Navigator.maybePop(context, result);
    } else {
      await load();
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (templates == null) return;

    setState(() {
      templates = templates!.reorder(oldIndex: oldIndex, newIndex: newIndex);
    });

    int length = templates!.items.length;
    for (int i = 0; i < length; i++) {
      final item = templates!.items[i];
      if (item.index != i) {
        await TemplateDbModel.db.set(item.copyWith(index: i, updatedAt: DateTime.now()));
      }
    }

    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: params.onlyMyTemplates
          ? AppBar(
              title: Text(tr('general.my_templates')),
              actions: [
                IconButton(
                  tooltip: tr('general.path_type.archives'),
                  icon: const Icon(SpIcons.archive),
                  onPressed: () => goToArchivesPage(context),
                ),
              ],
            )
          : null,
      body: buildBody(context),
      floatingActionButtonLocation: SpFabLocation.endFloat(context),
      floatingActionButton: params.viewingArchives || params.pickMode ? null : buildFAB(context),
    );
  }

  Widget buildFAB(BuildContext context) {
    if (MediaQuery.accessibleNavigationOf(context)) {
      return FloatingActionButton.extended(
        tooltip: tr('button.new_template'),
        elevation: 0.0,
        backgroundColor: ColorScheme.of(context).secondary,
        foregroundColor: ColorScheme.of(context).onSecondary,
        heroTag: null,
        onPressed: () => goToNewPage(context),
        label: Text(tr('button.new_template')),
        icon: const Icon(SpIcons.add),
        shape: const StadiumBorder(),
      );
    } else {
      return FloatingActionButton(
        tooltip: tr('button.new_template'),
        elevation: 0.0,
        backgroundColor: ColorScheme.of(context).secondary,
        foregroundColor: ColorScheme.of(context).onSecondary,
        heroTag: null,
        child: const Icon(SpIcons.add),
        onPressed: () => goToNewPage(context),
      );
    }
  }

  Widget buildBody(BuildContext context) {
    if (templates == null) return const Center(child: CircularProgressIndicator.adaptive());
    if (templates?.items.isEmpty == true) {
      return const _EmptyBody();
    }

    final padding = EdgeInsets.only(
      bottom: MediaQuery.of(context).padding.bottom + kToolbarHeight + 24.0,
    );

    if (params.pickMode) {
      return SpScrollConfiguration(
        child: ListView.builder(
          itemCount: templates!.items.length,
          padding: padding,
          itemBuilder: (context, index) {
            return _buildTemplateTile(context, templates!.items[index], index);
          },
        ),
      );
    }

    return SpScrollConfiguration(
      child: ReorderableListView.builder(
        itemCount: templates!.items.length,
        padding: padding,
        buildDefaultDragHandles: true,
        onReorderItem: (int oldIndex, int newIndex) => reorder(oldIndex, newIndex),
        proxyDecorator: (child, index, animation) {
          return Container(
            color: ColorScheme.of(context).readOnly.surface5,
            child: child,
          );
        },
        itemBuilder: (context, index) {
          return _buildTemplateTile(context, templates!.items[index], index);
        },
      ),
    );
  }

  Widget _buildTemplateTile(BuildContext context, TemplateDbModel template, int index) {
    final isLast = index == templates!.items.length - 1;

    return Column(
      key: ValueKey(template.id),
      mainAxisSize: MainAxisSize.min,
      children: [
        _TemplateTile(
          onTap: () => goToShowPage(context, template),
          template: template,
        ),
        if (!isLast)
          Divider(
            height: 1.0,
            indent: MediaQuery.paddingOf(context).left,
            endIndent: MediaQuery.paddingOf(context).right,
          ),
      ],
    );
  }
}
