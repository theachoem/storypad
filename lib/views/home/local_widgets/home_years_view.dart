import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/home/home_view_model.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';
import 'package:storypad/widgets/sp_text_inputs_page.dart';

class HomeYearsView extends StatefulWidget {
  const HomeYearsView({super.key});

  @override
  State<HomeYearsView> createState() => HomeYearsViewState();
}

class HomeYearsViewState extends State<HomeYearsView> {
  Map<int, int>? years;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    years = await StoryDbModel.db.getStoryCountsByYear(filters: {
      'types': [
        PathType.docs.name,
        PathType.archives.name,
      ]
    });

    if (years == null || years?.isEmpty == true) {
      years = {
        DateTime.now().year: 0,
      };
    }

    setState(() {});
  }

  Future<void> addYear(BuildContext context, HomeViewModel viewModel) async {
    dynamic result = await SpNestedNavigation.maybeOf(context)?.push(SpTextInputsPage(
      appBar: AppBar(title: Text(tr("page.add_year.title"))),
      fields: [
        SpTextInputField(
          hintText: tr("input.year.hint"),
          keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
          validator: (value) {
            int? year = int.tryParse(value ?? '');

            if (year == null) return tr("input.message.invalid");
            if (year > DateTime.now().year + 1000) return tr("input.message.invalid");
            if (years?.keys.contains(year) == true) return tr("input.message.already_exist");

            return null;
          },
        ),
      ],
    ));

    if (result is List<String> && result.isNotEmpty && context.mounted) {
      int year = int.parse(result.first);

      StoryDbModel initialStory = StoryDbModel.startYearStory(year);
      await StoryDbModel.db.set(initialStory);
      await load();
      await viewModel.changeYear(year);
    }
  }

  @override
  Widget build(BuildContext context) {
    HomeViewModel viewModel = Provider.of<HomeViewModel>(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async => addYear(context, viewModel),
          ),
        ],
      ),
      body: buildBody(viewModel),
    );
  }

  Widget buildBody(HomeViewModel viewModel) {
    if (years == null) return const Center(child: CircularProgressIndicator.adaptive());
    return ListView(
      children: [
        ...buildYearsTiles(viewModel),
      ],
    );
  }

  List<Widget> buildYearsTiles(HomeViewModel viewModel) {
    return years!.entries.map((entry) {
      bool selected = viewModel.year == entry.key;
      return SpSingleStateWidget.listen(
        initialValue: false,
        builder: (context, loading, loadingNotifier) {
          return Stack(
            children: [
              ListTile(
                onTap: () async {
                  loadingNotifier.value = true;
                  await viewModel.changeYear(entry.key);
                  loadingNotifier.value = false;
                },
                selected: selected,
                title: Text(entry.key.toString()),
                subtitle: Text(plural("plural.story", entry.value)),
                trailing: Visibility(visible: selected, child: const Icon(Icons.check)),
              ),
              AnimatedContainer(
                duration: Durations.long4,
                width: double.infinity,
                height: loading ? 4.0 : 0,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(),
                child: Wrap(
                  children: [LinearProgressIndicator()],
                ),
              ),
            ],
          );
        },
      );
    }).toList();
  }
}
