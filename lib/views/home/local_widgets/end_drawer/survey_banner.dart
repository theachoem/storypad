import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/services/remote_config/remote_config_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/core/storages/dimissed_surveys_storage.dart';
import 'package:storypad/views/home/home_view_model.dart' show HomeViewModel;
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SurveyBanner extends StatefulWidget {
  const SurveyBanner({
    super.key,
    required this.context,
    required this.viewModel,
  });

  final BuildContext context;
  final HomeViewModel viewModel;

  @override
  State<SurveyBanner> createState() => _SurveyBannerState();
}

class _SurveyBannerState extends State<SurveyBanner> {
  final DimissedSurveysStorage storage = DimissedSurveysStorage();
  String surveyUrl = RemoteConfigService.surveyUrl.get();

  bool show = false;

  @override
  void initState() {
    super.initState();

    if (surveyUrl.trim().isNotEmpty) {
      load();
    }
  }

  Future<void> load() async {
    final result = await DimissedSurveysStorage().readList();
    if (result != null && result.contains(surveyUrl)) {
      setState(() {
        show = false;
      });
    } else {
      setState(() {
        show = (widget.viewModel.stories?.items.length ?? 0) > 10;
      });
    }
  }

  Future<void> dimiss() async {
    await storage.add(surveyUrl);
    await load();
  }

  Future<void> openSurvey() async {
    await UrlOpenerService.openInCustomTab(context, RemoteConfigService.surveyUrl.get());
  }

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox();

    return SpFadeIn.bound(
      duration: Durations.long4,
      child: MaterialBanner(
        backgroundColor: Theme.of(context).colorScheme.readOnly.surface2,
        contentTextStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSecondary),
        padding: const EdgeInsetsDirectional.only(start: 16.0, top: 24.0, end: 16.0, bottom: 4.0).add(
          EdgeInsets.only(
            left: MediaQuery.of(context).padding.left,
            right: MediaQuery.of(context).padding.right,
          ),
        ),
        leading: Icon(SpIcons.forum, color: Theme.of(context).colorScheme.onSurface),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 4.0,
          children: [
            Text(
              tr("list_tile.survey.title"),
              style: TextTheme.of(context).titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
            Text(
              tr("list_tile.survey.message"),
              style: TextTheme.of(context).bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
        forceActionsBelow: true,
        actions: [
          TextButton(
            child: Text(tr("button.dimiss")),
            onPressed: () => dimiss(),
          ),
          FilledButton(
            child: Text(tr("button.take_survey")),
            onPressed: () => openSurvey(),
          ),
        ],
      ),
    );
  }
}
