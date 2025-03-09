import 'package:flutter/material.dart';
import 'package:storypad/views/onboarding/steps/step_1/onboarding_step_1_view.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/view/base_route.dart';

class OnboardingHelloRoute extends BaseRoute {
  OnboardingHelloRoute();

  @override
  bool get preferredNestedRoute => true;

  @override
  Widget buildPage(BuildContext context) => OnboardingHelloView(params: this);
}

class OnboardingHelloView extends StatefulWidget {
  const OnboardingHelloView({
    super.key,
    required this.params,
  });

  final OnboardingHelloRoute params;

  @override
  State<OnboardingHelloView> createState() => _OnboardingHelloViewState();
}

class _OnboardingHelloViewState extends State<OnboardingHelloView> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 2)).then((e) {
      final context = this.context;
      if (!context.mounted) return;

      OnboardingStep1Route().pushReplacement(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    double paddingTop = MediaQuery.of(context).padding.top + 56;
    double paddingBottom = MediaQuery.of(context).padding.bottom + 24;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        forceMaterialTransparency: true,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: EdgeInsets.only(
          top: paddingTop,
          bottom: paddingBottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "Hello Thea",
              style: TextTheme.of(context).titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.0),
            Text(
              "Let's explore StoryPad together!",
              style: TextTheme.of(context).bodyLarge,
              textAlign: TextAlign.center,
            ),
          ].asMap().entries.map((entry) {
            return SpFadeIn.fromTop(
              delay: Durations.medium4 + Durations.medium1 * entry.key,
              duration: Durations.long3,
              child: entry.value,
            );
          }).toList(),
        ),
      ),
    );
  }
}
