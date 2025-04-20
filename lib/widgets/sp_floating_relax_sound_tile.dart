import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/extensions/color_extension.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/services/timer_picker_service.dart';
import 'package:storypad/providers/relax_sounds_provider.dart';
import 'package:storypad/views/discover/discover_view.dart';
import 'package:storypad/views/discover/discover_view_model.dart';
import 'package:storypad/widgets/bottom_sheets/sp_discover_sheet.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_loop_animation_builder.dart';
import 'package:storypad/widgets/sp_refresh_state_in_duration.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

class SpFloatingRelaxSoundsTile extends StatelessWidget {
  const SpFloatingRelaxSoundsTile({
    super.key,
    this.fromHome = false,
  });

  final bool fromHome;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RelaxSoundsProvider>(context);

    if (!kHasRelaxSoundsFeature) return const SizedBox.shrink();
    if (provider.selectedRelaxSounds.lastOrNull == null) return const SizedBox.shrink();

    Color backgroundColor = ColorFromDayService(context: context).get(provider.selectedRelaxSounds.last.dayColor)!;

    return SpFadeIn.fromBottom(
      child: buildCardWithBackgrounds(
        context: context,
        backgroundColor: backgroundColor,
        provider: provider,
        child: buildContents(context, backgroundColor, provider),
        onTap: () {
          if (fromHome) {
            SpDiscoverSheet(
              params: const DiscoverRoute(initialPage: DiscoverSegmentId.relaxSounds),
            ).show(context: context);
          } else {
            showTimerPicker(provider, context);
          }
        },
      ),
    );
  }

  Widget buildCardWithBackgrounds({
    required BuildContext context,
    required Color backgroundColor,
    required RelaxSoundsProvider provider,
    required Widget child,
    required void Function()? onTap,
  }) {
    double radius = 12;
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16.0,
        left: MediaQuery.of(context).padding.left + 16.0,
        right: MediaQuery.of(context).padding.right + 16.0,
      ),
      child: Dismissible(
        key: ValueKey(provider.selectedRelaxSounds.lastOrNull?.translationKey),
        direction: DismissDirection.horizontal,
        onDismissed: (direction) => provider.dismiss(),
        child: AnimatedSwitcher(
          switchInCurve: Curves.easeInOutQuad,
          switchOutCurve: Curves.easeInOutQuad,
          duration: Durations.long1,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: Material(
            key: ValueKey(provider.selectedRelaxSounds.lastOrNull?.translationKey),
            elevation: 8.0,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
            child: SpTapEffect(
              effects: [SpTapEffectType.scaleDown],
              onTap: onTap,
              child: SpLoopAnimationBuilder(
                curve: Curves.linear,
                duration: const Duration(seconds: 3),
                reverseDuration: const Duration(seconds: 3),
                child: child,
                builder: (context, value, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color.lerp(backgroundColor, backgroundColor.darken(0.2), value)!,
                          Color.lerp(backgroundColor.darken(0.2), backgroundColor, value)!,
                        ],
                      ),
                    ),
                    child: child,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildContents(
    BuildContext context,
    Color backgroundColor,
    RelaxSoundsProvider provider,
  ) {
    Color foregroundColor = AppTheme.isDarkMode(context) ? backgroundColor.darken(0.5) : backgroundColor.lighten(0.8);

    return Row(
      spacing: 4.0,
      children: [
        IconButton(
          color: foregroundColor,
          icon: SpAnimatedIcons.fadeScale(
            duration: Durations.long1,
            firstChild: const Icon(SpIcons.pauseCircle),
            secondChild: const Icon(SpIcons.playCircle),
            showFirst: provider.playing,
          ),
          iconSize: 32.0,
          onPressed: () => provider.togglePlayPause(),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.selectedRelaxSounds.map((e) => e.label).join(", "),
                  style: TextTheme.of(context).titleMedium?.copyWith(color: foregroundColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.timerService.stopIn != null)
                  SpRefreshStateInDuration(
                    duration: const Duration(seconds: 1),
                    builder: (context) {
                      final date = DateTime(
                        2020,
                        1,
                        1,
                        provider.timerService.stopIn!.inHours % 60,
                        provider.timerService.stopIn!.inMinutes % 60,
                        provider.timerService.stopIn!.inSeconds % 60,
                      );

                      return Text(
                        tr('general.stop_in_args', namedArgs: {'TIMER': DateFormatHelper.Hms(date, context.locale)}),
                        style: TextTheme.of(context).bodyMedium?.copyWith(color: foregroundColor),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        if (fromHome)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              SpIcons.keyboardUp,
              color: foregroundColor,
            ),
          ),
        if (!fromHome)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              SpIcons.timer,
              color: foregroundColor,
            ),
          ),
      ],
    );
  }

  Future<void> showTimerPicker(RelaxSoundsProvider provider, BuildContext context) async {
    Duration initialStopTimer() {
      if (provider.timerService.stopIn == null || provider.timerService.ended) return const Duration(minutes: 30);
      return provider.timerService.stopIn!;
    }

    final duration = await TimePickerService(
      context: context,
      initialTimer: initialStopTimer(),
    ).showPicker();

    if (duration != null) {
      provider.setStopIn(duration);
    }
  }
}
