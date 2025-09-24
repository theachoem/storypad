part of '../library_view.dart';

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({
    required this.context,
  });

  final BuildContext context;

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
                const Icon(SpIcons.photo, size: 32.0),
                Text(
                  tr("page.library.empty_message"),
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
