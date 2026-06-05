part of 'home_quick_actions_view.dart';

class _HomeQuickActionsContent extends StatelessWidget {
  const _HomeQuickActionsContent(this.viewModel);

  final HomeQuickActionsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final iapProvider = Provider.of<InAppPurchaseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('page.home_quick_actions.title')),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 120),
        children: [
          _Preview(viewModel: viewModel),
          const SizedBox(height: 16),
          _AvailableActions(
            viewModel: viewModel,
            onChooseTemplate: () => _chooseTemplate(context, iapProvider),
            onChooseTag: () => _chooseTag(context, iapProvider),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseTemplate(BuildContext context, InAppPurchaseProvider iapProvider) async {
    if (!iapProvider.isProUser) {
      const PaywallRoute(initialFocus: .customizations).push(context);
      return;
    }

    if (viewModel.limitReached) return;

    final result = await const SpTemplatesPickerSheet().show(context: context);
    if (result != null && result is TemplatePickResult) viewModel.addTemplate(result);
  }

  Future<void> _chooseTag(BuildContext context, InAppPurchaseProvider iapProvider) async {
    if (!iapProvider.isProUser) {
      const PaywallRoute(initialFocus: .customizations).push(context);
      return;
    }

    if (viewModel.limitReached) return;

    final remaining = viewModel.actionLimit - viewModel.enabledCount;
    final result = await SpTagsPickerSheet(
      selectedTagIds: viewModel.selectedTagIds,
      maxCount: remaining,
    ).show<List<TagDbModel>>(context: context);
    if (result == null || result.isEmpty) return;

    for (final tag in result) {
      viewModel.addTag(tag);
    }
  }
}
