part of 'story_pages_builder.dart';

class _AddPageButton extends StatelessWidget {
  const _AddPageButton({
    required this.onAddPage,
  });

  final void Function() onAddPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: IconButton.outlined(
        onPressed: onAddPage,
        style: IconButton.styleFrom(side: BorderSide(color: Theme.of(context).dividerColor)),
        iconSize: 20.0,
        icon: const Icon(SpIcons.add),
      ),
    );
  }
}
