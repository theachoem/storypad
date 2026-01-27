import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/views/home/home_view_model.dart';
import 'package:storypad/views/home/local_widgets/end_drawer/home_end_drawer_state.dart';
import 'package:storypad/widgets/sp_icons.dart';

class HomeYearSwitcherHeader extends StatelessWidget {
  const HomeYearSwitcherHeader({
    super.key,
    required this.homeViewModel,
  });

  final HomeViewModel homeViewModel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        homeViewModel.endDrawerState = HomeEndDrawerState.showYearsView;
        homeViewModel.notifyListeners();
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4.0,
          children: [
            Text(
              homeViewModel.year.toString(),
              style: TextTheme.of(context).displayMedium?.copyWith(color: ColorScheme.of(context).primary),
            ),
            Text.rich(
              TextSpan(
                text: "${tr("button.switch")} ",
                style: TextTheme.of(context).labelLarge,
                children: const [
                  WidgetSpan(
                    child: Icon(SpIcons.keyboardDown, size: 16.0),
                    alignment: PlaceholderAlignment.middle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
