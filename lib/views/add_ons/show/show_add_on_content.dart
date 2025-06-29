part of 'show_add_on_view.dart';

class _ShowAddOnContent extends StatelessWidget {
  const _ShowAddOnContent(this.viewModel);

  final ShowAddOnViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(forceMaterialTransparency: true),
      body: ListView(
        children: [
          buildContents(context),
          buildDemoImages(),
        ],
      ),
    );
  }

  Widget buildContents(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: ColorFromDayService(context: context).get(viewModel.params.addOn.weekdayColor),
            foregroundColor: ColorScheme.of(context).onPrimary,
            child: Icon(viewModel.params.addOn.iconData),
          ),
          const SizedBox(height: 12.0),
          Text(
            viewModel.params.addOn.title,
            style: TextTheme.of(context).titleLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            viewModel.params.addOn.subtitle,
            style: TextTheme.of(context).bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12.0),
          Row(
            spacing: 8.0,
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: Text(viewModel.params.addOn.displayPrice),
                ),
              ),
              Expanded(
                child: OutlinedButton(
                  child: Text(tr('button.try')),
                  onPressed: () => const RelaxSoundsRoute().push(context, rootNavigator: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildDemoImages() {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: viewModel.params.addOn.demoImages.length,
        scrollDirection: Axis.horizontal,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => SpImagesViewer.fromString(
              initialIndex: index,
              images: viewModel.params.addOn.demoImages,
            ).show(context),
            child: ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: viewModel.params.addOn.demoImages[index],
              ),
            ),
          );
        },
      ),
    );
  }
}
