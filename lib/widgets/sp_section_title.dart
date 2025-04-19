import 'package:flutter/material.dart';

class SpSectionTitle extends StatelessWidget {
  const SpSectionTitle({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Text(
        title,
        style: TextTheme.of(context).titleSmall?.copyWith(color: ColorScheme.of(context).primary),
      ),
    );
  }
}
