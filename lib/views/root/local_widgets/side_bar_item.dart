part of '../root_view.dart';

class _SideBarItem extends StatelessWidget {
  const _SideBarItem({
    required this.onTap,
    required this.leading,
    required this.routeName,
    required this.title,
    required this.viewModel,
  });

  final Widget? leading;
  final String routeName;
  final String title;
  final void Function() onTap;
  final RootViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ValueListenableBuilder(
        valueListenable: viewModel.selectedRootRouteNameNotifier,
        child: Row(
          mainAxisAlignment: .start,
          crossAxisAlignment: .center,
          spacing: 12.0,
          children: [
            if (leading != null) SizedBox.square(dimension: 32, child: leading),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                style: TextTheme.of(context).titleMedium,
              ),
            ),
          ],
        ),
        builder: (context, selectedRootRouteName, contents) {
          bool selected = selectedRootRouteName == routeName;
          return Container(
            padding: EdgeInsets.only(
              left: _RootContent.leadingPaddedSize,
              top: 8.0,
              bottom: 8.0,
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
