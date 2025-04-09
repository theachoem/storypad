part of 'pin_unlock_view.dart';

class _PinUnlockContent extends StatelessWidget {
  const _PinUnlockContent(this.viewModel);

  final PinUnlockViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double itemSize = MediaQuery.textScalerOf(context).scale(72.0);
      final double spacing = MediaQuery.textScalerOf(context).scale(16.0);
      final double pinSize = MediaQuery.textScalerOf(context).scale(16.0);

      bool landscape = constraints.maxWidth > constraints.maxHeight;
      bool displayInRow = landscape && constraints.maxHeight < 700;

      final children = [
        Flexible(child: buildPinPreview(context, pinSize)),
        Flexible(child: FittedBox(child: buildPins(itemSize, spacing, context))),
      ];

      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          forceMaterialTransparency: true,
          automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
          actions: [
            if (CupertinoSheetRoute.hasParentSheet(context))
              CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context))
          ],
        ),
        body: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16.0),
          child: displayInRow ? Row(children: children) : Column(children: children),
        ),
      );
    });
  }

  Widget buildPinPreview(BuildContext context, double pinSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        (viewModel.pin.length >= 4) && !viewModel.params.validator(viewModel.pin)
            ? Text(
                viewModel.params.invalidPinTitle,
                style: TextTheme.of(context).titleLarge,
                textAlign: TextAlign.center,
              )
            : Text(
                viewModel.params.title,
                style: TextTheme.of(context).titleLarge,
                textAlign: TextAlign.center,
              ),
        const SizedBox(height: 24),
        SizedBox(
          height: pinSize,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: pinSize,
            children: List.generate(viewModel.pin.length, (index) {
              final bool invalid = viewModel.pin.length >= 4 && !viewModel.params.validator(viewModel.pin);
              return Visibility(
                visible: viewModel.pin.length > index,
                child: SpFadeIn.bound(
                  child: Container(
                    width: pinSize,
                    height: pinSize,
                    decoration: BoxDecoration(
                      color: invalid ? ColorScheme.of(context).error : ColorScheme.of(context).primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget buildPins(double itemSize, double spacing, BuildContext context) {
    return SizedBox(
      width: itemSize * 3 + spacing * 2,
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(12, (index) {
          Widget? child;
          Color? backgroundColor = ColorScheme.of(context).surface;
          Color? borderColor = ColorScheme.of(context).onSurface.withValues(alpha: 0.1);

          void Function()? onPressed;

          if (index < 9) {
            int pin = index + 1;
            onPressed = () => viewModel.addPin(context, pin);

            child = Container(
              width: itemSize,
              constraints: BoxConstraints(minHeight: itemSize),
              alignment: Alignment.center,
              child: Text(
                pin.toString(),
                style: TextTheme.of(context).headlineMedium,
                textAlign: TextAlign.center,
              ),
            );
          } else if (index == 9) {
            if (viewModel.params.onConfirmWithBiometrics != null) {
              onPressed = () => viewModel.confirmWithBiometrics(context);
              backgroundColor = null;

              child = Container(
                width: itemSize,
                constraints: BoxConstraints(minHeight: itemSize),
                alignment: Alignment.center,
                child: Icon(
                  SpIcons.fingerprint,
                  size: itemSize / 2 - 4.0,
                ),
              );
            }
          } else if (index == 10) {
            onPressed = () => viewModel.addPin(context, 0);
            child = Container(
              width: itemSize,
              constraints: BoxConstraints(minHeight: itemSize),
              alignment: Alignment.center,
              child: Text(
                "0",
                style: TextTheme.of(context).headlineSmall,
                textAlign: TextAlign.center,
              ),
            );
          } else if (index == 11) {
            borderColor = null;
            onPressed = viewModel.pin.isEmpty ? () {} : () => viewModel.removeLastPin();
            backgroundColor = null;
            child = Container(
              width: itemSize,
              constraints: BoxConstraints(minHeight: itemSize),
              alignment: Alignment.center,
              child: Icon(SpIcons.backspace, size: itemSize / 2 - 8.0),
            );
          }

          if (child == null) {
            borderColor = null;
            return SizedBox(
              width: itemSize,
            );
          }

          return Material(
            color: backgroundColor,
            shape: CircleBorder(side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed != null
                  ? () {
                      HapticFeedback.selectionClick();
                      onPressed!();
                    }
                  : null,
              child: child,
            ),
          );
        }),
      ),
    );
  }
}
