import 'package:flutter/material.dart';

class DiscoverCalendarContent extends StatelessWidget {
  const DiscoverCalendarContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(itemBuilder: (context, index) => const Text("DiscoverCalendarContent")),
    );
  }
}
