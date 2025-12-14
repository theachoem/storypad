import 'package:flutter/material.dart';

class SpSectionTitle extends StatelessWidget {
  const SpSectionTitle({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 4.0,
          ).add(
            EdgeInsets.only(
              left: MediaQuery.of(context).padding.left,
              right: MediaQuery.of(context).padding.right,
            ),
          ),
      child: Row(
        spacing: 8.0,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextTheme.of(context).titleSmall?.copyWith(color: ColorScheme.of(context).primary),
            ),
          ),
          if (trailing != null) ...[
            trailing!,
          ],
        ],
      ),
    );
  }
}
