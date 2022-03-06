library not_found_view;

import 'package:responsive_builder/responsive_builder.dart';
import 'package:flutter/material.dart';
import 'package:spooky/core/base/view_model_provider.dart';
import 'package:spooky/widgets/sp_pop_button.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'not_found_view_model.dart';

part 'not_found_mobile.dart';
part 'not_found_tablet.dart';
part 'not_found_desktop.dart';

class NotFoundView extends StatelessWidget {
  const NotFoundView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<NotFoundViewModel>(
      create: (_) => NotFoundViewModel(),
      builder: (context, viewModel, child) {
        return ScreenTypeLayout(
          mobile: _NotFoundMobile(viewModel),
          desktop: _NotFoundDesktop(viewModel),
          tablet: _NotFoundTablet(viewModel),
        );
      },
    );
  }
}
