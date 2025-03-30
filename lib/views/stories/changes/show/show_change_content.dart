part of 'show_change_view.dart';

class _ShowChangeContent extends StatelessWidget {
  const _ShowChangeContent(this.viewModel);

  final ShowChangeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (viewModel.params.content.richPages?.length != null && viewModel.params.content.richPages!.length > 1) ...[
            buildPageIndicator(),
            const SizedBox(width: 12.0),
          ],
        ],
      ),
      body: buildBody(context),
    );
  }

  Widget buildBody(BuildContext context) {
    if (viewModel.quillControllers == null) return const Center(child: CircularProgressIndicator.adaptive());
    return PageView.builder(
      itemCount: viewModel.quillControllers?.length ?? 0,
      onPageChanged: (value) => viewModel.currentPageNotifier.value = value,
      itemBuilder: (context, index) {
        return NestedScrollView(
          headerSliverBuilder: (context, _) {
            return [
              SliverToBoxAdapter(
                child: TextFormField(
                  initialValue: viewModel.params.content.richPages?[index].title,
                  readOnly: true,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: null,
                  maxLength: null,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: tr("input.title.hint"),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  ),
                ),
              ),
            ];
          },
          body: QuillEditor.basic(
            controller: viewModel.quillControllers!.elementAt(index),
            config: QuillEditorConfig(
              padding: const EdgeInsets.all(16.0),
              checkBoxReadOnly: true,
              showCursor: false,
              autoFocus: false,
              expands: true,
              embedBuilders: [
                SpImageBlockEmbed(
                    fetchAllImages: () => StoryExtractImageFromContentService.call(viewModel.params.content)),
                SpDateBlockEmbed(),
              ],
              unknownEmbedBuilder: SpQuillUnknownEmbedBuilder(),
            ),
          ),
        );
      },
    );
  }

  Widget buildPageIndicator() {
    return Container(
      height: 48.0,
      alignment: Alignment.center,
      child: ValueListenableBuilder<int>(
        valueListenable: viewModel.currentPageNotifier,
        builder: (context, currentPage, child) {
          return Text('${viewModel.currentPage + 1} / ${viewModel.params.content.richPages?.length}');
        },
      ),
    );
  }
}
