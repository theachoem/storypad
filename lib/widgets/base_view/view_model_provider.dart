import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewModelProvider<T extends ChangeNotifier> extends StatelessWidget {
  const ViewModelProvider({
    super.key,
    required this.builder,
    required this.create,
    this.child,
  });

  final Create<T> create;
  final Widget? child;
  final Widget Function(BuildContext context, T viewModel, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>(
      create: (BuildContext context) => create(context),
      child: child,
      builder: (context, child) {
        T viewModel = Provider.of<T>(context);
        return builder(context, viewModel, child);
      },
    );
  }
}
