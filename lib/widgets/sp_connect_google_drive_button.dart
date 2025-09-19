import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpConnectGoogleDriveButton extends StatelessWidget {
  const SpConnectGoogleDriveButton({
    super.key,
    required this.onPressed,
  });

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
    return FilledButton.icon(
      icon: Icon(SpIcons.googleDrive),
      label: Text(tr("button.connect")),
      onPressed: onPressed,
    );
  }

  Widget _buildCupertinoPinButton(BuildContext context) {
    return CupertinoButton.filled(
      sizeStyle: CupertinoButtonSize.medium,
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8.0,
        children: [
          Icon(SpIcons.googleDrive),
          Text(tr("button.connect")),
        ],
      ),
    );
  }
}
