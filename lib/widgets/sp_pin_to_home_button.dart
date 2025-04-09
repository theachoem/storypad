import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpPinToHomeButton extends StatelessWidget {
  const SpPinToHomeButton({
    super.key,
    required this.pinned,
    required this.disabled,
    required this.onPressed,
  });

  final bool pinned;
  final bool disabled;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    if (kIsCupertino) {
      return _buildCupertinoPinButton(context);
    } else {
      return _buildMaterialPinButton(context);
    }
  }

  Widget _buildMaterialPinButton(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(pinned ? SpIcons.pinSlash : SpIcons.pin, color: ColorScheme.of(context).primary),
      label: Text(pinned ? tr("button.unpin_from_home") : tr("button.pin_to_home")),
      onPressed: pinned ? null : onPressed,
    );
  }

  Widget _buildCupertinoPinButton(BuildContext context) {
    return CupertinoButton.tinted(
      sizeStyle: CupertinoButtonSize.medium,
      onPressed: pinned ? null : onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8.0,
        children: [
          Icon(pinned ? SpIcons.pinSlash : SpIcons.pin),
          Text(pinned ? tr("button.unpin_from_home") : tr("button.pin_to_home")),
        ],
      ),
    );
  }
}
