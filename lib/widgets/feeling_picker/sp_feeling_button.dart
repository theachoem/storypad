import 'package:animated_clipper/animated_clipper.dart';
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/feeling_object.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/widgets/feeling_picker/sp_feeling_picker.dart';
import 'package:storypad/widgets/sp_floating_pop_up_button.dart';
import 'dart:math';

class SpFeelingButton extends StatefulWidget {
  const SpFeelingButton({
    super.key,
    required this.onPicked,
    required this.feeling,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String? feeling;
  final void Function(String? feeling) onPicked;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<SpFeelingButton> createState() => _SpFeelingButtonState();
}

class _SpFeelingButtonState extends State<SpFeelingButton> {
  late final ConfettiController excitingController;
  late final ConfettiController heartController;
  late final ConfettiController blowingController;

  @override
  void initState() {
    excitingController = ConfettiController(duration: const Duration(seconds: 5));
    heartController = ConfettiController(duration: const Duration(seconds: 5));
    blowingController = ConfettiController(duration: const Duration(seconds: 5));
    super.initState();
  }

  @override
  void dispose() {
    excitingController.dispose();
    heartController.dispose();
    blowingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiWidget(
      blastDirection: pi * 6,
      confettiController: blowingController,
      shouldLoop: false,
      blastDirectionality: BlastDirectionality.directional,
      createParticlePath: (size) => drawHeart(size),
      colors: ColorFromDayService(context: context).colors().values.toList(),
      child: ConfettiWidget(
        confettiController: heartController,
        shouldLoop: false,
        blastDirectionality: BlastDirectionality.explosive,
        createParticlePath: (size) => drawHeart(size),
        colors: [ColorFromDayService(context: context).get(DateTime.sunday)!],
        child: ConfettiWidget(
          confettiController: excitingController,
          shouldLoop: false,
          blastDirectionality: BlastDirectionality.explosive,
          createParticlePath: (size) => drawStar(size),
          colors: ColorFromDayService(context: context).colors().values.toList(),
          child: buildButton(),
        ),
      ),
    );
  }

  Widget buildButton() {
    return SpFloatingPopUpButton(
      estimatedFloatingWidth: 300,
      bottomToTop: false,
      dyGetter: (dy) => dy + 64,
      pathBuilder: PathBuilders.slideDown,
      floatingBuilder: (void Function() callback) {
        return SpFeelingPicker(
          feeling: widget.feeling,
          onPicked: (feeling) {
            HapticFeedback.selectionClick();

            widget.onPicked(feeling);
            callback();

            switch (feeling) {
              case "excited":
                excitingController.play();
                Future.delayed(const Duration(seconds: 1)).then((value) {
                  excitingController.stop();
                });
                break;
              case "in_love":
                heartController.play();
                Future.delayed(const Duration(seconds: 1)).then((value) {
                  heartController.stop();
                });
                break;
              case "blowing":
                blowingController.play();
                Future.delayed(const Duration(seconds: 1)).then((value) {
                  blowingController.stop();
                });
                break;
              default:
            }
          },
        );
      },
      builder: (callback) {
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Material(
            type: MaterialType.circle,
            color: widget.backgroundColor ?? ColorScheme.of(context).readOnly.surface1,
            child: Tooltip(
              message: FeelingObject.feelingsMap[widget.feeling]?.translation(context) ?? tr("button.set_feeling"),
              child: InkWell(
                borderRadius: BorderRadius.circular(48.0),
                onTap: callback,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: FeelingObject.feelingsMap[widget.feeling]?.image64.image(width: 24) ??
                      Icon(Icons.add_reaction_sharp, color: widget.foregroundColor),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Path drawHeart(Size size) {
    double width = size.width;
    double height = size.height;

    Path path = Path();
    path.moveTo(0.5 * width, height * 0.35);
    path.cubicTo(0.2 * width, height * 0.1, -0.25 * width, height * 0.6, 0.5 * width, height);
    path.moveTo(0.5 * width, height * 0.35);
    path.cubicTo(0.8 * width, height * 0.1, 1.25 * width, height * 0.6, 0.5 * width, height);

    return path;
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step), halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }
}
