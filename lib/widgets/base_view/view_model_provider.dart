import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef Create<T> = T Function(BuildContext context);
typedef CreateWithTicker<T> = T Function(BuildContext context, TickerProvider tickerProvider);

class ViewModelProvider<T extends ChangeNotifier> extends StatelessWidget {
  const ViewModelProvider({
    super.key,
    required this.builder,
    required this.create,
    this.child,
  });

  static Widget withSingleTicker<T extends ChangeNotifier>({
    Key? key,
    required Widget Function(BuildContext context, T viewModel, Widget? child) builder,
    required CreateWithTicker<T> create,
    Widget? child,
  }) {
    return _ViewModelProviderWithSingleTicker<T>(
      key: key,
      builder: builder,
      create: create,
      child: child,
    );
  }

  static Widget withMultiTickers<T extends ChangeNotifier>({
    Key? key,
    required Widget Function(BuildContext context, T viewModel, Widget? child) builder,
    required CreateWithTicker<T> create,
    Widget? child,
  }) {
    return _ViewModelProviderWithMultiTickers<T>(
      key: key,
      builder: builder,
      create: create,
      child: child,
    );
  }

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

class _ViewModelProviderWithSingleTicker<T extends ChangeNotifier> extends StatefulWidget {
  const _ViewModelProviderWithSingleTicker({
    super.key,
    required this.builder,
    required this.create,
    this.child,
  });

  final CreateWithTicker<T> create;
  final Widget? child;
  final Widget Function(BuildContext context, T viewModel, Widget? child) builder;

  @override
  State<_ViewModelProviderWithSingleTicker<T>> createState() => _ViewModelProviderWithSingleTickerState<T>();
}

class _ViewModelProviderWithSingleTickerState<T extends ChangeNotifier>
    extends State<_ViewModelProviderWithSingleTicker<T>>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>(
      create: (BuildContext context) => widget.create(context, this),
      child: widget.child,
      builder: (context, child) {
        T viewModel = Provider.of<T>(context);
        return widget.builder(context, viewModel, child);
      },
    );
  }
}

class _ViewModelProviderWithMultiTickers<T extends ChangeNotifier> extends StatefulWidget {
  const _ViewModelProviderWithMultiTickers({
    super.key,
    required this.builder,
    required this.create,
    this.child,
  });

  final CreateWithTicker<T> create;
  final Widget? child;
  final Widget Function(BuildContext context, T viewModel, Widget? child) builder;

  @override
  State<_ViewModelProviderWithMultiTickers<T>> createState() => _ViewModelProviderWithMultiTickersState<T>();
}

class _ViewModelProviderWithMultiTickersState<T extends ChangeNotifier>
    extends State<_ViewModelProviderWithMultiTickers<T>>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>(
      create: (BuildContext context) => widget.create(context, this),
      child: widget.child,
      builder: (context, child) {
        T viewModel = Provider.of<T>(context);
        return widget.builder(context, viewModel, child);
      },
    );
  }
}
