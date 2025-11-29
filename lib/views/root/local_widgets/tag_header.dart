part of '../root_view.dart';

class _TagHeader extends StatelessWidget {
  const _TagHeader(this.viewModel);

  final RootViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (viewModel.navigatorKey.currentContext == null) return;
        context.read<TagsProvider>().addTag(viewModel.navigatorKey.currentContext!);
      },
      child: Padding(
        padding: const EdgeInsets.only(
          left: _RootContent.leadingPaddedSize + 4.0,
          top: 4.0,
          bottom: 4.0,
          right: 8.0,
        ),
        child: Row(
          mainAxisAlignment: .start,
          crossAxisAlignment: .center,
          children: [
            Expanded(
              child: Text(
                tr('general.tags'),
                style: TextTheme.of(context).titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox.square(
              dimension: 32,
              child: Icon(
                SpIcons.add,
                size: 20.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
