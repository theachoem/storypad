part of '../home_quick_actions_view.dart';

class _AvailableActions extends StatelessWidget {
  const _AvailableActions({
    required this.viewModel,
    required this.onChooseTemplate,
    required this.onChooseTag,
  });

  final HomeQuickActionsViewModel viewModel;
  final VoidCallback onChooseTemplate;
  final VoidCallback onChooseTag;

  @override
  Widget build(BuildContext context) {
    viewModel.setAvailableTileBuilder(_buildAvailableTile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpSectionTitle(
          title: tr('button.add_app_shortcuts'),
          trailing: SpCapacityBadge(current: viewModel.enabledCount, max: viewModel.actionLimit),
        ),
        AnimatedList(
          key: viewModel.availableActionsListKey,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          initialItemCount: viewModel.availableItems.length + 2,
          itemBuilder: (context, index, animation) {
            if (index < viewModel.availableItems.length) {
              return _buildAvailableTile(viewModel.availableItems[index], animation);
            }

            final pickerIndex = index - viewModel.availableItems.length;
            final pickerTile = pickerIndex == 0
                ? _ActionTile(
                    icon: SpIcons.file,
                    title: tr('button.choose_template'),
                    locked: !context.read<InAppPurchaseProvider>().isProUser,
                    enabled: !viewModel.limitReached,
                    onTap: onChooseTemplate,
                  )
                : _ActionTile(
                    icon: SpIcons.tag,
                    title: tr('button.choose_tag'),
                    locked: !context.read<InAppPurchaseProvider>().isProUser,
                    enabled: !viewModel.limitReached,
                    onTap: onChooseTag,
                  );

            return FadeTransition(
              opacity: animation.drive(CurveTween(curve: Curves.ease)),
              child: pickerTile,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAvailableTile(HomeQuickActionItem action, Animation<double> animation) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.ease);

    return SizeTransition(
      sizeFactor: curved,
      child: _ActionTile(
        icon: action.icon,
        title: action.label,
        enabled: !viewModel.limitReached,
        onTap: () => viewModel.addAction(action),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.locked = false,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool locked;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16.0, right: 8.0),
      leading: Icon(icon),
      title: Text(title),
      trailing: IconButton(
        tooltip: title,
        icon: Icon(locked ? SpIcons.lock : SpIcons.add),
        onPressed: enabled ? onTap : null,
      ),
      onTap: enabled ? onTap : null,
    );
  }
}
