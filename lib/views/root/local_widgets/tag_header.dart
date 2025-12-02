part of '../root_view.dart';

class _TagHeader extends StatelessWidget {
  const _TagHeader(this.viewModel);

  final RootViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => viewModel.navigate(TagsRoute.routeName, TagsRoute()),
      child: ValueListenableBuilder(
        valueListenable: viewModel.selectedRootRouteNameNotifier,
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
                SpIcons.edit,
                size: 20.0,
              ),
            ),
          ],
        ),
        builder: (context, selectedRootRouteName, contents) {
          bool selected = selectedRootRouteName == TagsRoute.routeName;

          return Container(
            padding: EdgeInsets.only(
              left: _RootContent.leadingPaddedSize + 4.0,
              top: 4.0,
              bottom: 4.0,
              right: selected ? 4.0 : 8.0,
            ),
            decoration: BoxDecoration(
              border: selected
                  ? Border(
                      right: BorderSide(
                        color: ColorScheme.of(context).primary,
                        width: 4.0,
                      ),
                    )
                  : null,
            ),
            child: contents,
          );
        },
      ),
    );
  }
}
