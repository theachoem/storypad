part of home_view;

class _HomeMobile extends StatefulWidget {
  final HomeViewModel viewModel;

  const _HomeMobile(
    this.viewModel, {
    Key? key,
  }) : super(key: key);

  @override
  State<_HomeMobile> createState() => _HomeMobileState();
}

class _HomeMobileState extends State<_HomeMobile> with SingleTickerProviderStateMixin {
  late TabController controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 12, vsync: this);
    controller.addListener(() {
      if (controller.animation!.value % 10 == controller.index) {
        widget.viewModel.onTabChange(controller.index + 1);
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: headerSliverBuilder,
        body: SpTabView(
          controller: controller,
          children: List.generate(
            controller.length,
            (index) {
              return StoryList(
                year: 2022,
                month: index + 1,
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> headerSliverBuilder(context, scroll) {
    return [
      buildAppBar(),
    ];
  }

  Widget buildAppBar() {
    return HomeAppBar(
      title: "Hello Sothea 📝",
      subtitle: "2021 - 100 Stories",
      tabController: controller,
      tabLabels: List.generate(
        12,
        (index) {
          return DateFormatHelper.toNameOfMonth().format(
            DateTime(2020, index + 1),
          );
        },
      ),
    );
  }
}
