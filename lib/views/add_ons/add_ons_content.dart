part of 'add_ons_view.dart';

class _AddOnsContent extends StatelessWidget {
  const _AddOnsContent(this.viewModel);

  final AddOnsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('page.add_ons.title')),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        separatorBuilder: (context, index) => const SizedBox(height: 16.0),
        itemCount: viewModel.addOns.length,
        itemBuilder: (context, index) {
          final addOn = viewModel.addOns[index];
          return _AddOnCard(
            addOn: addOn,
            onTap: () => ShowAddOnRoute(addOn: addOn).push(context),
          );
        },
      ),
    );
  }
}
