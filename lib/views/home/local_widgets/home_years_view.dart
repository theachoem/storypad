import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/home/home_view_model.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';
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
      appBar: AppBar(title: const Text("Add Year")),
      fields: [
        SpTextInputField(
          hintText: 'eg. 2004',
          keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
          validator: (value) {
            int? year = int.tryParse(value ?? '');

            if (year == null) return "Invalid";
            if (year > DateTime.now().year + 1000) return "Invalid";
            if (years?.keys.contains(year) == true) return "Already exist!";

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
      return ListTile(
        onTap: () => viewModel.changeYear(entry.key),
        selected: selected,
        title: Text(entry.key.toString()),
        subtitle: Text(entry.value > 1 ? "${entry.value} stories" : "${entry.value} story"),
        trailing: Visibility(
          visible: selected,
          child: const Icon(Icons.check),
        ),
      );
    }).toList();
  }
}
