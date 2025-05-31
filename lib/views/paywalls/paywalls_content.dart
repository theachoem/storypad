part of 'paywalls_view.dart';

class _PaywallsContent extends StatelessWidget {
  const _PaywallsContent(this.viewModel);

  final PaywallsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    if (viewModel.errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Text(viewModel.errorMessage!),
      );
    }

    if (viewModel.offerings == null) return const Center(child: CircularProgressIndicator.adaptive());
    return Text(
      viewModel.offerings?.all.toString() ?? 'N/A',
    );
  }
}
