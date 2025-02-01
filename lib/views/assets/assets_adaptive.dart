part of 'assets_view.dart';

class _AssetsAdaptive extends StatelessWidget {
  const _AssetsAdaptive(this.viewModel);

  final AssetsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final assets = viewModel.assets ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Gallery (${assets.length})"),
      ),
      body: MasonryGridView.builder(
        padding: EdgeInsets.all(16.0).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16.0),
        itemCount: assets.length,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemBuilder: (context, index) {
          final asset = assets[index];

          Widget? content;

          if (asset.localFile != null) {
            content = Image.file(
              asset.localFile!,
              fit: BoxFit.cover,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4.0,
            children: [
              Material(
                borderRadius: BorderRadius.circular(8.0),
                color: ColorScheme.of(context).readOnly.surface2,
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () async {
                    if (content != null) {
                      ShowAssetRoute(assetId: asset.id, storyViewOnly: false).push(context);
                    } else {
                      final result = await showOkCancelAlertDialog(
                        context: context,
                        title: asset.originalSource,
                        isDestructiveAction: true,
                        okLabel: "Delete",
                      );

                      if (result == OkCancelResult.ok) {
                        await asset.delete();
                        await viewModel.load();
                      }
                    }
                  },
                  child: content ??
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 8.0,
                          children: [
                            Icon(Icons.info),
                            Expanded(child: Text("File not found")),
                          ],
                        ),
                      ),
                ),
              ),
              Text("${viewModel.storiesCount[asset.id]} stories")
            ],
          );
        },
      ),
    );
  }
}
