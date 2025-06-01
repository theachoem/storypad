part of '../templates_view.dart';

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: constraints.maxHeight,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12.0,
              children: [
                Icon(SpIcons.book, size: 32.0),
                Text(
                  tr('page.templates.empty_message'),
                  textAlign: TextAlign.center,
                  style: TextTheme.of(context).bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
