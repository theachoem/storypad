import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/views/home/home_view_model.dart';

part 'sp_story_list_multi_edit_wrapper_state.dart';

class SpStoryListMultiEditWrapper extends StatelessWidget {
  const SpStoryListMultiEditWrapper({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context) builder;

  static SpStoryListMultiEditWrapperState of(BuildContext context) {
    return context.read<SpStoryListMultiEditWrapperState>();
  }

  static tryListen({
    required BuildContext context,
    required Widget Function(BuildContext context, SpStoryListMultiEditWrapperState? state) builder,
  }) {
    bool hasProvider = false;

    try {
      context.read<SpStoryListMultiEditWrapperState>();
      hasProvider = true;
    } catch (e) {
      hasProvider = false;
    }

    if (!hasProvider) {
      return builder(context, null);
    }

    return Consumer<SpStoryListMultiEditWrapperState>(
      builder: (context, state, child) {
        return builder(context, state);
      },
    );
  }

  static listen({
    required BuildContext context,
    required Widget Function(BuildContext context, SpStoryListMultiEditWrapperState state) builder,
  }) {
    return Consumer<SpStoryListMultiEditWrapperState>(
      builder: (context, state, child) {
        return builder(context, state);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableProvider(
      create: (context) => SpStoryListMultiEditWrapperState(),
      builder: (context, child) => builder(context),
    );
  }
}
