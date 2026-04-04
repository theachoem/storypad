import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SpProBadge extends StatelessWidget {
  const SpProBadge({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ColorScheme.of(context).secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        // tr('general.user_type.free')
        tr('general.user_type.pro'),
        style: TextTheme.of(context).labelMedium?.copyWith(
          color: ColorScheme.of(context).onSecondary,
        ),
      ),
    );
  }
}
