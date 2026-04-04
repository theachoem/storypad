import 'dart:async';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/matrix_4_extension.dart';
import 'package:storypad/widgets/sp_page_view_datas.dart';

class SpPageView extends StatefulWidget {
  const SpPageView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    required this.itemCount,
    this.onPageChanged,
    this.physics,
  });

  final PageController controller;
  final int? itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollPhysics? physics;
  final ValueChanged<int>? onPageChanged;

  @override
  State<SpPageView> createState() => _SpPageViewState();
}

class _SpPageViewState extends State<SpPageView> {
  late ValueNotifier<double> offsetNotifier;

  @override
  void initState() {
    offsetNotifier = ValueNotifier(0);
    initializeController().then((value) {
      widget.controller.addListener(_listener);
    });
    super.initState();
  }

  void _listener() {
    if (widget.controller.hasClients) offsetNotifier.value = widget.controller.offset;
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_listener);
    offsetNotifier.dispose();
  }

  double get width => MediaQuery.of(context).size.width;
  PageController get controller => widget.controller;

  late final Completer<bool> completer = Completer<bool>();
  Future<bool> initializeController() {
    if (completer.isCompleted) return Future.value(true);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (completer.isCompleted) return;
      completer.complete(true);
    });

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: widget.itemCount,
      controller: widget.controller,
      physics: widget.physics,
      onPageChanged: widget.onPageChanged,
      itemBuilder: (context, itemIndex) {
        return FutureBuilder(
          future: initializeController(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            return ValueListenableBuilder<double>(
              valueListenable: offsetNotifier,
              child: widget.itemBuilder(context, itemIndex),
              builder: (context, value, child) {
                SpPageViewDatas datas = SpPageViewDatas.fromOffset(
                  itemIndex: itemIndex,
                  controller: controller,
                  width: width,
                );

                return Transform(
                  transform: Matrix4.identity()
                    ..spTranslate(datas.translateX1)
                    ..spTranslate(datas.translateX2),
                  child: Opacity(
                    opacity: datas.opacity,
                    child: child,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
