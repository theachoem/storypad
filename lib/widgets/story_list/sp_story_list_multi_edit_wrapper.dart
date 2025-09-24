import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/views/home/home_view.dart';

part 'sp_story_list_multi_edit_wrapper_state.dart';

class SpStoryListMultiEditWrapper extends StatelessWidget {
  const SpStoryListMultiEditWrapper({
    super.key,
    required this.builder,
    this.disabled = false,
  });

  final bool disabled;
  final Widget Function(BuildContext context) builder;

  static SpStoryListMultiEditWrapperState of(BuildContext context) {
    return context.read<SpStoryListMultiEditWrapperState>();
  }

  static Widget tryListen({
    required BuildContext context,
    required Widget Function(BuildContext context, SpStoryListMultiEditWrapperState? state) builder,
  }) {
    bool shouldListen;

    try {
      final state = context.read<SpStoryListMultiEditWrapperState>();
      shouldListen = !state.disabled;
    } catch (e) {
      shouldListen = false;
    }

    if (!shouldListen) {
      return builder(context, null);
    }

    return Consumer<SpStoryListMultiEditWrapperState>(
      builder: (context, state, child) {
        return builder(context, state);
      },
    );
  }

  static Consumer<SpStoryListMultiEditWrapperState> listen({
    required BuildContext context,
    required Widget Function(BuildContext context, SpStoryListMultiEditWrapperState state) builder,
  }) {
    return Consumer<SpStoryListMultiEditWrapperState>(
      builder: (context, state, child) {
        return builder(context, state);
      },
    );
  }

  factory SpStoryListMultiEditWrapper.withListener({
    required Widget Function(BuildContext context, SpStoryListMultiEditWrapperState state) builder,
  }) {
    return SpStoryListMultiEditWrapper(builder: (context) {
      return Consumer<SpStoryListMultiEditWrapperState>(
        builder: (context, state, child) {
          return builder(context, state);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableProvider(
      create: (context) => SpStoryListMultiEditWrapperState(disabled: disabled),
      builder: (context, child) => builder(context),
    );
  }
}
