import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';

class StoryTitle extends StatelessWidget {
  const StoryTitle({
    super.key,
    required this.content,
    required this.changeTitle,
    required this.backgroundColor,
    this.scrollable = true,
  });

  final StoryContentDbModel? content;
  final void Function() changeTitle;
  final Color backgroundColor;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => changeTitle(),
      child: SizedBox(
        width: double.infinity,
        height: kToolbarHeight,
        child: scrollable
            ? buildScrollableTitle(context)
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: AppBarTheme.of(context).titleSpacing!),
                child: buildTitle(context),
              ),
      ),
    );
  }

  Widget buildScrollableTitle(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppBarTheme.of(context).titleSpacing!),
          scrollDirection: Axis.horizontal,
          child: buildTitle(context),
        ),
        Positioned(
          bottom: 0,
          top: 0,
          right: 0,
          child: Container(
            width: 8,
            height: kToolbarHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  backgroundColor.withValues(alpha: 0.0),
                  backgroundColor,
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget buildTitle(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      alignment: Alignment.centerLeft,
      child: Text(
        content?.title ?? 'Title...',
        textAlign: TextAlign.left,
        style: AppBarTheme.of(context).titleTextStyle,
      ),
    );
  }
}
