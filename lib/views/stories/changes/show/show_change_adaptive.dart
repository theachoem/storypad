part of 'show_change_view.dart';

class _ShowChangeAdaptive extends StatelessWidget {
  const _ShowChangeAdaptive(this.viewModel);

  final ShowChangeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(viewModel.params.content.title ?? '')),
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    if (viewModel.quillControllers == null) return const Center(child: CircularProgressIndicator.adaptive());
    return PageView.builder(
      itemCount: viewModel.quillControllers?.length ?? 0,
      itemBuilder: (context, index) {
        return QuillEditor.basic(
          controller: viewModel.quillControllers!.values.elementAt(index),
          config: QuillEditorConfig(
            padding: const EdgeInsets.all(16.0),
            checkBoxReadOnly: true,
            showCursor: false,
            autoFocus: false,
            expands: true,
            embedBuilders: [
              ImageBlockEmbed(fetchAllImages: () => QuillService.imagesFromContent(viewModel.params.content)),
              DateBlockEmbed(),
            ],
            unknownEmbedBuilder: UnknownEmbedBuilder(),
          ),
        );
      },
    );
  }
}
