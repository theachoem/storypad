import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/matrix_4_extension.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/views/home/home_view_model.dart' show HomeViewModel;
import 'package:storypad/views/home/local_widgets/end_drawer/home_end_drawer_state.dart';
import 'package:storypad/views/home/years/home_years_view.dart' show HomeYearsRoute, HomeYearsView;
import 'package:storypad/widgets/side_items/side_items.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_theme_mode_icon.dart';

class HomeEndDrawer extends StatelessWidget {
  const HomeEndDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);

    if (viewModel.endDrawerState == HomeEndDrawerState.showYearsView) {
      if (viewModel.showFadeInYearEndDrawer) {
        return Material(
          color: ColorScheme.of(context).surface,
          child: SpFadeIn(
            builder: (context, animation, child) {
              return SpFadeIn(
                child: AnimatedBuilder(
                  animation: animation,
                  child: child,
                  builder: (context, child) {
                    return Transform(
                      transform: Matrix4.identity()..spTranslate(lerpDouble(24.0, 0, animation.value)!, 0.0),
                      child: child,
                    );
                  },
                ),
              );
            },
            child: HomeYearsView(
              params: HomeYearsRoute(viewModel: viewModel),
            ),
          ),
        );
      } else {
        return HomeYearsView(
          params: HomeYearsRoute(viewModel: viewModel),
        );
      }
    }

    final sideItems = SideItems.getEndDrawerItems(viewModel);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: SpThemeModeIcon(parentContext: context),
            onPressed: () => context.read<DevicePreferencesProvider>().toggleThemeMode(context),
          ),
        ],
      ),
      body: ListView(
        controller: PrimaryScrollController.maybeOf(context),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          bottom: MediaQuery.of(context).padding.bottom + 16.0,
        ),
        children: sideItems.map((item) {
          if (item is CustomSideItem) {
            return item.builder(context);
          } else if (item is ListTileSideItem) {
            return ListTile(
              leading: item.icon,
              title: Text(item.title),
              subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
              onTap: () => item.onTap(context),
            );
          }
          return const SizedBox.shrink();
        }).toList(),
      ),
    );
  }
}
