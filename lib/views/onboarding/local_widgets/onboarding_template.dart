import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storypad/core/services/remote_config/remote_config_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

part 'privacy_policy_text.dart';
part 'onboarding_step_indicator.dart';

class OnboardingTemplate extends StatelessWidget {
  const OnboardingTemplate({
    super.key,
    required this.title,
    required this.description,
    required this.actionButton,
    required this.demo,
    required this.currentStep,
    required this.maxStep,
  });

  final String title;
  final String description;
  final Widget? demo;
  final Widget actionButton;
  final int currentStep;
  final int maxStep;

  @override
  Widget build(BuildContext context) {
    double staturBarHeight = MediaQuery.of(context).padding.top;
    double bottomBarHeight = MediaQuery.of(context).padding.bottom + 24;

    double dividerHeight = demo == null ? 0 : 1;
    double spacingBetweenSection = 36;
    double demoHeight = demo == null ? 240 : 360.0 + 48.0;

    double pageHeight = MediaQuery.of(context).size.height;
    double contentHeight =
        pageHeight - (staturBarHeight + bottomBarHeight + dividerHeight + spacingBetweenSection + demoHeight);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        leading:
            ModalRoute.of(context)?.canPop == true ? Hero(tag: 'onboarding-back-button', child: BackButton()) : null,
      ),
      body: SingleChildScrollView(
        reverse: true,
        padding: EdgeInsets.only(
          top: staturBarHeight,
          bottom: bottomBarHeight,
        ),
        child: Column(
          children: [
            Container(
              height: demoHeight,
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(),
              child: GestureDetector(
                onTap: () => HapticFeedback.selectionClick(),
                child: demo,
              ),
            ),
            if (demo != null) Hero(tag: "onboarding-divider", child: Divider(height: dividerHeight)),
            SizedBox(height: spacingBetweenSection),
            Container(
              width: double.infinity,
              height: max(200, contentHeight),
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildTextPresentation(context),
                  buildFooter(context),
                ].asMap().entries.map((entry) {
                  return SpFadeIn.fromTop(
                    delay: Duration(milliseconds: 500) + Durations.medium1 * entry.key,
                    duration: Durations.medium4,
                    child: entry.value,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextPresentation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextTheme.of(context).titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          constraints: BoxConstraints(maxWidth: 250),
          child: Text(
            description,
            style: TextTheme.of(context).bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget buildFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (currentStep != maxStep) ...[
          _OnboardingStepIndicator(currentStep: currentStep, maxStep: maxStep),
          const SizedBox(height: 24.0),
        ],
        if (currentStep == maxStep) ...[
          _PrivacyPolicyText(context: context),
          const SizedBox(height: 24.0),
        ],
        actionButton,
      ],
    );
  }
}
