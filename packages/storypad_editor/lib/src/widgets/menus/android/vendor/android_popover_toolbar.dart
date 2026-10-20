// Vendored from super_editor (commit fbf5d192f2c9a412ddb194ce06e25c457acf0fcb; the file is unchanged up to the pinned
// ad86b14448c01f90b79f2e6c615bd21ea6cb26a0), super_editor/lib/src/infrastructure/flutter/android_toolbar.dart. Changed only where marked `StoryPad:` (and this
// header): the open ⋮ menu is capped in height and scrolls, as native Android's does (upstream and Flutter's own
// Material toolbar grow it past the screen instead), and opening or closing it animates as native's does (upstream
// snaps the items and grows linearly): see _RenderOverflowMorph. And with a ⋮ menu, the toolbar takes the open menu's
// room from the start, so its host places it where the menu fits and opening it never moves the toolbar (upstream:
// the host re-places the grown toolbar, flipping it below the text when it no longer fits above): see
// _TextSelectionToolbarTrailingEdgeAlign.
// It's not part of super_editor's public API, so importing it from `package:super_editor/src/...` would couple this
// package to an internal path that can change without notice.
//
// super_editor license (MIT):
// Copyright (c) 2021 Superlist, SuperDeclarative! and the contributors
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright
// notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
//
// The code is itself extracted from Flutter's Material text selection toolbar (BSD license, Copyright 2014 The
// Flutter Authors).

// Kept byte-for-byte with upstream (easier to re-sync), so its lints are its own:
// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, prefer_initializing_formals

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../android_toolbar_placement.dart';

part 'android_popover_toolbar_container.dart';

const double _kToolbarHeight = 54.0;

// StoryPad: native Android's open ⋮ menu shows at most four and a half items (the half hinting it scrolls).
const double _kOverflowItemHeight = 48.0;
const double _kOverflowMaxHeight = _kOverflowItemHeight * 4.5;

// StoryPad: opening or closing the ⋮ menu animates as native Android's floating toolbar does -- its values, from AOSP
// frameworks/base core/java/com/android/internal/widget/floatingtoolbar/LocalFloatingToolbarPopup.java
// (openOverflow, closeOverflow, getAdjustedDuration, LogAccelerateInterpolator) and core/res/res/interpolator/.
const Curve _kFastOutSlowIn = Cubic(0.4, 0.0, 0.2, 1.0);
const Curve _kLinearOutSlowIn = Cubic(0.0, 0.0, 0.2, 1.0);
const Curve _kFastOutLinearIn = Cubic(0.4, 0.0, 1.0, 1.0);
const Curve _kLogAccelerate = _LogAccelerateCurve();

// The longest any part of it runs (a far morph's size); each part ends at its own time within it.
const Duration _kMorphWindow = Duration(milliseconds: 300);

// StoryPad: AOSP's LogAccelerateInterpolator.
class _LogAccelerateCurve extends Curve {
  const _LogAccelerateCurve();

  static const int _base = 100;

  static double _log(double t) => 1 - math.pow(_base, -t).toDouble();

  @override
  double transformInternal(double t) => 1 - _log(1 - t) / _log(1);
}

/// A toolbar containing the given children. If they overflow the width
/// available, then the overflowing children will be displayed in an overflow
/// menu.
///
/// Extracted from Flutter's Material text selection toolbar implementation
/// from flutter/packages/flutter/lib/src/material/text_selection_toolbar.dart
class AndroidPopoverToolbar extends StatefulWidget {
  const AndroidPopoverToolbar({
    required this.isAbove,
    this.anchorRect,
    this.anchorChanges,
    this.gapAbove = 8,
    this.gapBelow = 8,
    required this.toolbarBuilder,
    required this.children,
  });

  final List<Widget> children;

  // When true, the toolbar fits above its anchor and will be positioned there.
  // StoryPad: with [anchorRect], only the first guess: the toolbar then finds its side itself.
  final bool isAbove;

  // StoryPad: the global rect of what the toolbar points at (the selection). Given, the toolbar compares its own
  // place on screen against it after each layout (and on [anchorChanges]) to know which side its host put it on --
  // which, with the ⋮ menu's room taken, depends on that room -- and shows only once it knows.
  final ValueGetter<Rect?>? anchorRect;
  final Listenable? anchorChanges;

  // StoryPad: how far the host puts the toolbar above and below its anchor (for the room the open menu has there).
  final double gapAbove;
  final double gapBelow;

  // Builds the toolbar that will be populated with the children and fit inside
  // of the layout that adjusts to overflow.
  final ToolbarBuilder toolbarBuilder;

  @override
  _AndroidPopoverToolbarState createState() => _AndroidPopoverToolbarState();
}

class _AndroidPopoverToolbarState extends State<AndroidPopoverToolbar> with TickerProviderStateMixin {
  // Whether or not the overflow menu is open. When it is closed, the menu
  // items that don't overflow are shown. When it is open, only the overflowing
  // menu items are shown.
  bool _overflowOpen = false;

  // StoryPad: the closed layout's last item that fits (-1: none overflows), as last laid out; the open menu shows the
  // ones after it, as last built ([_builtLastIndexThatFits], caught up a frame later: see _afterLayout).
  int _lastIndexThatFits = -1;
  int _builtLastIndexThatFits = -1;

  // StoryPad: the side of its anchor the toolbar is on, and whether it's settled enough (its side and its open menu
  // known) to show. Without an anchorRect, the given side, shown at once.
  late bool _isAbove = widget.isAbove;
  late bool _placed = widget.anchorRect == null;
  bool _placementCheckScheduled = false;

  // StoryPad: the closed toolbar's and open menu's sizes, from _RenderOverflowMorph's layout, for the room
  // _TextSelectionToolbarTrailingEdgeAlign takes.
  final _OverflowMetrics _metrics = _OverflowMetrics();

  // StoryPad: native's placement for the toolbar (its side, and its open menu's items), from the last check; the one
  // it would choose there, and the side the host put the toolbar on regardless of it, if it did; and the least
  // height the toolbar's room takes (to make the host put it below). See _settlePlacement.
  AndroidToolbarPlacement? _plan;
  AndroidToolbarPlacement? _naturalPlan;
  bool? _hostSide;
  double _minRoomHeight = 0;

  // StoryPad: runs while the toolbar morphs between closed and open (see _RenderOverflowMorph).
  late final AnimationController _morph = AnimationController(vsync: this, duration: _kMorphWindow)
    ..addStatusListener((AnimationStatus status) {
      // Settled: drop the panel no longer shown.
      if (status.isCompleted && mounted) setState(() {});
    });

  // The key for _TextSelectionToolbarTrailingEdgeAlign.
  UniqueKey _containerKey = UniqueKey();

  // Close the menu and reset layout calculations, as in when the menu has
  // changed and saved values are no longer relevant. This should be called in
  // setState or another context where a rebuild is happening.
  void _reset() {
    // Change _TextSelectionToolbarTrailingEdgeAlign's key when the menu changes
    // in order to cause it to rebuild. This lets it recalculate its
    // saved width for the new set of children, and it prevents AnimatedSize
    // from animating the size change.
    _containerKey = UniqueKey();
    // If the menu items change, make sure the overflow menu is closed. This
    // prevents getting into a broken state where _overflowOpen is true when
    // there are not enough children to cause overflow.
    _overflowOpen = false;
    _morph.stop();
  }

  @override
  void initState() {
    super.initState();
    widget.anchorChanges?.addListener(_afterLayout);
  }

  @override
  void didUpdateWidget(AndroidPopoverToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the children are changing at all, the current page should be reset.
    if (!listEquals(widget.children, oldWidget.children)) {
      _reset();
    }
    if (widget.anchorChanges != oldWidget.anchorChanges) {
      oldWidget.anchorChanges?.removeListener(_afterLayout);
      widget.anchorChanges?.addListener(_afterLayout);
    }
    if (widget.anchorRect == null) {
      _isAbove = widget.isAbove;
    }
  }

  @override
  void dispose() {
    widget.anchorChanges?.removeListener(_afterLayout);
    _morph.dispose();
    super.dispose();
  }

  // StoryPad: after the frame, catch up with what layout found: the open menu's items, and the toolbar's side.
  void _afterLayout() {
    if (_placementCheckScheduled) return;
    _placementCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _placementCheckScheduled = false;
      if (mounted) _settlePlacement();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _settlePlacement() {
    final bool itemsChanged = _builtLastIndexThatFits != _lastIndexThatFits;
    final Rect? anchor = widget.anchorRect?.call();
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    bool? observedAbove;
    if (anchor != null && box != null && box.attached && box.hasSize) {
      observedAbove = box.localToGlobal(box.size.center(Offset.zero)).dy < anchor.center.dy;
    }

    // Placed as native places it (see AndroidToolbarPlacement.place): re-placed as the selection moves, while closed and still.
    AndroidToolbarPlacement? plan = _plan;
    double minRoomHeight = _minRoomHeight;
    final int overflowCount = _lastIndexThatFits == -1 ? 0 : widget.children.length - _lastIndexThatFits;
    if (overflowCount == 0) {
      plan = null;
      minRoomHeight = 0;
    } else if (anchor != null && !_overflowOpen && !_morph.isAnimating) {
      final MediaQueryData view = MediaQueryData.fromView(View.of(context));
      final Rect viewport = Rect.fromLTRB(
        0,
        view.padding.top,
        view.size.width,
        view.size.height - math.max(view.viewInsets.bottom, view.padding.bottom),
      );
      AndroidToolbarPlacement place({bool? side}) => AndroidToolbarPlacement.place(
        selection: anchor,
        viewport: viewport,
        overflowCount: overflowCount,
        gapAbove: widget.gapAbove,
        gapBelow: widget.gapBelow,
        side: side,
      );
      final AndroidToolbarPlacement natural = place();
      if (natural != _naturalPlan) {
        _hostSide = null;
      } else if (_hostSide == null && plan == natural && observedAbove != null && observedAbove != natural.isAbove) {
        // Laid out for it, the host put the toolbar on the other side regardless: the menu for that side.
        _hostSide = observedAbove;
      }
      _naturalPlan = natural;
      plan = _hostSide == null ? natural : place(side: _hostSide);

      // Below: as tall as makes the host give up on above (its rules: super_editor's aligner flips once the toolbar is
      // taller than the room above the selection less 16; the reader's position delegate once taller than that less 48
      // and the status bar), as far as it fits below.
      minRoomHeight = 0;
      if (!plan.isAbove && _hostSide == null) {
        final double fitsBelow = view.size.height - anchor.bottom - widget.gapBelow;
        minRoomHeight = math.max(0, math.min(anchor.top - 15, fitsBelow));
      }
    }

    final bool planChanged = plan != _plan;
    final bool isAbove = (planChanged ? plan?.isAbove : observedAbove) ?? observedAbove ?? _isAbove;
    final bool changed = itemsChanged || planChanged || isAbove != _isAbove || minRoomHeight != _minRoomHeight;
    if (!changed && _placed) return;
    setState(() {
      _builtLastIndexThatFits = _lastIndexThatFits;
      _plan = plan;
      _minRoomHeight = minRoomHeight;
      _isAbove = isAbove;
      // Shown once a frame finds nothing left to catch up with.
      _placed = _placed || !changed;
    });
  }

  // StoryPad: as native's, the button does nothing while the toolbar morphs.
  void _toggleOverflow() {
    if (_morph.isAnimating) return;
    setState(() {
      _overflowOpen = !_overflowOpen;
    });
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) _morph.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final TextDirection textDirection = Directionality.of(context);

    // TODO(justinmc): This overflow button should have its own slot in
    // _TextSelectionToolbarItemsLayout separate from children, similar
    // to how it's done in Cupertino's text selection menu.
    // https://github.com/flutter/flutter/issues/69908
    // StoryPad: the navButton that shows and hides the overflow menu is its own child of _OverflowMorph (it slides
    // between the panels, as native's), and each panel keeps an invisible stand-in in its place.
    final Widget navButton = _TextSelectionToolbarOverflowButton(
      key: _overflowOpen ? StandardComponentType.backButton.key : StandardComponentType.moreButton.key,
      // A stand-in for native's animated morph between the two.
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Icon(_overflowOpen ? Icons.arrow_back : Icons.more_vert, key: ValueKey<bool>(_overflowOpen)),
      ),
      onPressed: _toggleOverflow,
      tooltip: _overflowOpen ? localizations.backButtonTooltip : localizations.moreButtonTooltip,
    );
    final Widget navSlot = Visibility.maintain(
      visible: false,
      child: _TextSelectionToolbarOverflowButton(icon: const Icon(null), onPressed: () {}),
    );

    return _TextSelectionToolbarTrailingEdgeAlign(
      key: _containerKey,
      overflowOpen: _overflowOpen,
      textDirection: textDirection,
      isAbove: _isAbove,
      metrics: _metrics,
      minHeight: _minRoomHeight,
      visible: _placed,
      child: widget.toolbarBuilder(
        context,
        _OverflowMorph(
          morph: _morph,
          open: _overflowOpen,
          isAbove: _isAbove,
          textDirection: textDirection,
          metrics: _metrics,
          onLayout: _afterLayout,
          children: <Widget>[
            _TextSelectionToolbarItemsLayout(
              isAbove: _isAbove,
              overflowOpen: false,
              textDirection: textDirection,
              onLayout: (int lastIndexThatFits) => _lastIndexThatFits = lastIndexThatFits,
              children: <Widget>[navSlot, ...widget.children],
            ),
            // StoryPad: the open menu is our own scrollable column, not the items layout's (uncapped) vertical one.
            // Built (and laid out) while closed too, for the room it needs.
            if (_builtLastIndexThatFits != -1) _buildOverflowMenu(navSlot) else const SizedBox.shrink(),
            navButton,
          ],
        ),
      ),
    );
  }

  // StoryPad: the overflowing items, at most [_kOverflowMaxHeight] tall and scrolling past it, with the back button's
  // row below them when the menu opens upwards (above them otherwise). As wide as the widest item, plus the upstream
  // vertical layout's 20.
  Widget _buildOverflowMenu(Widget navSlot) {
    // The layout's children are the nav button, then `widget.children`: the ones after its last fitting index.
    final List<Widget> items = widget.children.sublist(
      math.min(math.max(_builtLastIndexThatFits, 0), widget.children.length),
    );
    final Widget list = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: _plan?.listHeight ?? _kOverflowMaxHeight),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: items),
      ),
    );
    final Widget back = Align(alignment: AlignmentDirectional.centerStart, child: navSlot);

    return IntrinsicWidth(
      child: _ExtraIntrinsicWidth(
        extra: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _isAbove ? <Widget>[list, back] : <Widget>[back, list],
        ),
      ),
    );
  }
}

// StoryPad: the closed toolbar, the open menu and the ⋮/back button, morphing between closed and open as native
// Android's floating toolbar does (LocalFloatingToolbarPopup.openOverflow/closeOverflow):
// - The size: 250ms, 200 or 300 for a morph under 150 or over 300 (getAdjustedDuration). Opening, the width on
//   LogAccelerate and the height on FastOutSlowIn; closing, the other way round.
// - The panels stay put on screen (the toolbar's trailing edge, and its edge facing the selection, are fixed) and
//   are clipped by the morphing size. Opening, the closed one fades out (250ms, LinearOutSlowIn) while the open one
//   shows at once; closing, the closed one fades in (100ms, FastOutLinearIn) and the open one out (150ms,
//   LinearOutSlowIn).
// - The button slides from the closed toolbar's trailing end to the open menu's leading one (or back), on
//   FastOutSlowIn over the size's time.
// - Nothing takes a tap until it settles.
class _OverflowMorph extends MultiChildRenderObjectWidget {
  const _OverflowMorph({
    required this.morph,
    required this.open,
    required this.isAbove,
    required this.textDirection,
    required this.metrics,
    required this.onLayout,
    required super.children,
  });

  final Animation<double> morph;
  final bool open;
  final bool isAbove;
  final TextDirection textDirection;

  // Written with the panels' sizes, and whether the closed toolbar overflows (and so shows the button), on each layout.
  final _OverflowMetrics metrics;
  final VoidCallback onLayout;

  @override
  _RenderOverflowMorph createRenderObject(BuildContext context) {
    return _RenderOverflowMorph(
      morph: morph,
      open: open,
      isAbove: isAbove,
      textDirection: textDirection,
      metrics: metrics,
      onLayout: onLayout,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderOverflowMorph renderObject) {
    renderObject
      ..morph = morph
      ..open = open
      ..isAbove = isAbove
      ..textDirection = textDirection
      ..metrics = metrics
      ..onLayout = onLayout;
  }

  @override
  _OverflowMorphElement createElement() => _OverflowMorphElement(this);
}

class _OverflowMorphElement extends MultiChildRenderObjectElement {
  _OverflowMorphElement(super.widget);

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    final _RenderOverflowMorph morph = renderObject as _RenderOverflowMorph;
    children.where((Element child) => morph._isShown(child.renderObject! as RenderBox)).forEach(visitor);
  }
}

class _OverflowMorphParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderOverflowMorph extends RenderBox with ContainerRenderObjectMixin<RenderBox, _OverflowMorphParentData> {
  _RenderOverflowMorph({
    required Animation<double> morph,
    required bool open,
    required bool isAbove,
    required TextDirection textDirection,
    required this.metrics,
    required this.onLayout,
  }) : _morph = morph,
       _open = open,
       _isAbove = isAbove,
       _textDirection = textDirection;

  Animation<double> _morph;
  set morph(Animation<double> value) {
    if (value == _morph) return;
    if (attached) _morph.removeListener(markNeedsLayout);
    _morph = value;
    if (attached) _morph.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  bool _open;
  set open(bool value) {
    if (value == _open) return;
    _open = value;
    markNeedsLayout();
  }

  bool _isAbove;
  set isAbove(bool value) {
    if (value == _isAbove) return;
    _isAbove = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  _OverflowMetrics metrics;
  VoidCallback onLayout;

  RenderBox get _closedPanel => firstChild!;
  RenderBox get _openPanel => childAfter(firstChild!)!;
  RenderBox get _navButton => lastChild!;

  double _closedOpacity = 1;
  double _openOpacity = 0;
  bool _showsNavButton = false;
  bool _settled = true;

  final LayerHandle<ClipRectLayer> _clipLayer = LayerHandle<ClipRectLayer>();
  final LayerHandle<OpacityLayer> _closedLayer = LayerHandle<OpacityLayer>();
  final LayerHandle<OpacityLayer> _openLayer = LayerHandle<OpacityLayer>();

  bool _isShown(RenderBox child) {
    if (child == _navButton) return _showsNavButton;
    return (child == _openPanel ? _openOpacity : _closedOpacity) > 0;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _OverflowMorphParentData) child.parentData = _OverflowMorphParentData();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _morph.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _morph.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void dispose() {
    _clipLayer.layer = null;
    _closedLayer.layer = null;
    _openLayer.layer = null;
    super.dispose();
  }

  static double _progress(double elapsed, int milliseconds) => math.min(1.0, elapsed / milliseconds);

  static void _place(RenderBox child, Offset offset) => (child.parentData! as _OverflowMorphParentData).offset = offset;

  static Offset _offsetOf(RenderBox child) => (child.parentData! as _OverflowMorphParentData).offset;

  @override
  void performLayout() {
    final BoxConstraints loose = constraints.loosen();
    for (RenderBox? child = firstChild; child != null; child = childAfter(child)) {
      child.layout(loose, parentUsesSize: true);
    }
    final Size closedSize = _closedPanel.size;
    final Size openSize = _openPanel.size;
    _showsNavButton = metrics.hasOverflow =
        (_closedPanel as _RenderTextSelectionToolbarItemsLayout)._lastIndexThatFits != -1;
    metrics
      ..closedSize = closedSize
      ..openSize = openSize;
    final Size from = _open ? closedSize : openSize;
    final Size to = _open ? openSize : closedSize;

    double t = 1;
    _closedOpacity = _open ? 0 : 1;
    _openOpacity = _open ? 1 : 0;
    _settled = true;
    if (_morph.isAnimating) {
      final double elapsed = _morph.value * _kMorphWindow.inMilliseconds;
      // getAdjustedDuration(250), from how far the toolbar morphs (in dp).
      final double distance = Offset(closedSize.width - openSize.width, openSize.height - closedSize.height).distance;
      final int sizeMilliseconds = distance < 150 ? 200 : (distance > 300 ? 300 : 250);
      t = _progress(elapsed, sizeMilliseconds);
      if (_open) {
        _closedOpacity = 1 - _kLinearOutSlowIn.transform(_progress(elapsed, 250));
      } else {
        _closedOpacity = _kFastOutLinearIn.transform(_progress(elapsed, 100));
        _openOpacity = 1 - _kLinearOutSlowIn.transform(_progress(elapsed, 150));
      }
      _settled = t >= 1 && elapsed >= (_open ? 250 : 150);
    }

    final Curve widthCurve = _open ? _kLogAccelerate : _kFastOutSlowIn;
    final Curve heightCurve = _open ? _kFastOutSlowIn : _kLogAccelerate;
    size = constraints.constrain(
      Size(
        from.width + (to.width - from.width) * widthCurve.transform(t),
        from.height + (to.height - from.height) * heightCurve.transform(t),
      ),
    );

    final bool rtl = _textDirection == TextDirection.rtl;
    Offset anchored(Size child) =>
        Offset(rtl ? 0 : size.width - child.width, _isAbove ? size.height - child.height : 0);
    metrics.size = size;
    onLayout();
    _place(_closedPanel, anchored(closedSize));
    _place(_openPanel, anchored(openSize));

    // Where each panel keeps its stand-in: the closed toolbar's trailing end (its top), the open menu's leading end
    // (on the row facing the selection).
    final Size navSize = _navButton.size;
    final Offset closedNav = _offsetOf(_closedPanel) + Offset(rtl ? 0 : closedSize.width - navSize.width, 0);
    final Offset openNav =
        _offsetOf(_openPanel) +
        Offset(rtl ? openSize.width - navSize.width : 0, _isAbove ? openSize.height - navSize.height : 0);
    _place(
      _navButton,
      Offset.lerp(_open ? closedNav : openNav, _open ? openNav : closedNav, _kFastOutSlowIn.transform(t))!,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _clipLayer.layer = context.pushClipRect(needsCompositing, offset, Offset.zero & size, (
      PaintingContext context,
      Offset offset,
    ) {
      // Native's order: the open menu, the closed toolbar, the button.
      _paintPanel(context, offset, _openPanel, _openOpacity, _openLayer);
      _paintPanel(context, offset, _closedPanel, _closedOpacity, _closedLayer);
      if (_showsNavButton) context.paintChild(_navButton, offset + _offsetOf(_navButton));
    }, oldLayer: _clipLayer.layer);
  }

  void _paintPanel(
    PaintingContext context,
    Offset offset,
    RenderBox panel,
    double opacity,
    LayerHandle<OpacityLayer> layer,
  ) {
    if (opacity <= 0) {
      layer.layer = null;
    } else if (opacity >= 1) {
      layer.layer = null;
      context.paintChild(panel, offset + _offsetOf(panel));
    } else {
      layer.layer = context.pushOpacity(
        offset,
        (opacity * 255).round(),
        (PaintingContext context, Offset offset) => context.paintChild(panel, offset + _offsetOf(panel)),
        oldLayer: layer.layer,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (!_settled) return false;
    for (final RenderBox child in <RenderBox>[if (_showsNavButton) _navButton, _open ? _openPanel : _closedPanel]) {
      final bool isHit = result.addWithPaintOffset(
        offset: _offsetOf(child),
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) => child.hitTest(result, position: transformed),
      );
      if (isHit) return true;
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitor(_open ? _openPanel : _closedPanel);
    if (_showsNavButton) visitor(_navButton);
  }
}

// When the overflow menu is open, it tries to align its trailing edge to the
// trailing edge of the closed menu. This widget handles this effect by
// measuring and maintaining the width of the closed menu and aligning the child
// to that side.
//
// StoryPad: with a ⋮ menu, it also takes the open menu's room from the start, closed or open: as wide and as tall as
// the wider and taller of the closed toolbar and the open menu (from [metrics]), the toolbar at its trailing edge and
// at the edge facing its anchor ([isAbove]: the bottom), the rest see-through to taps. Its host (super_editor's
// aligner, or the reader's position delegate) puts it above the selection only when that room fits there, so the
// menu opens where it fits without the toolbar moving: above, opening upwards, or right away below, opening
// downwards. (Native's LocalFloatingToolbarPopup.refreshCoordinatesAndOverflowDirection decides the same way, also
// shrinking the menu to the room it has, and can keep the toolbar above while opening the menu downwards over the
// text; the hosts here can't place a toolbar like that.) Painted only once [visible].
class _TextSelectionToolbarTrailingEdgeAlign extends SingleChildRenderObjectWidget {
  const _TextSelectionToolbarTrailingEdgeAlign({
    super.key,
    required Widget super.child,
    required this.overflowOpen,
    required this.textDirection,
    required this.isAbove,
    required this.metrics,
    this.minHeight = 0,
    required this.visible,
  });

  final bool overflowOpen;
  final TextDirection textDirection;
  final bool isAbove;
  final _OverflowMetrics metrics;
  final double minHeight;
  final bool visible;

  @override
  _TextSelectionToolbarTrailingEdgeAlignRenderBox createRenderObject(BuildContext context) {
    return _TextSelectionToolbarTrailingEdgeAlignRenderBox(overflowOpen: overflowOpen, textDirection: textDirection)
      ..isAbove = isAbove
      ..metrics = metrics
      ..minHeight = minHeight
      ..visible = visible;
  }

  @override
  void updateRenderObject(BuildContext context, _TextSelectionToolbarTrailingEdgeAlignRenderBox renderObject) {
    renderObject
      ..overflowOpen = overflowOpen
      ..textDirection = textDirection
      ..isAbove = isAbove
      ..metrics = metrics
      ..minHeight = minHeight
      ..visible = visible;
  }
}

class _TextSelectionToolbarTrailingEdgeAlignRenderBox extends RenderProxyBox {
  _TextSelectionToolbarTrailingEdgeAlignRenderBox({required bool overflowOpen, required TextDirection textDirection})
    : _textDirection = textDirection,
      _overflowOpen = overflowOpen,
      super();

  // The width of the menu when it was closed. This is used to achieve the
  // behavior where the open menu aligns its trailing edge to the closed menu's
  // trailing edge.
  double? _closedWidth;

  bool _overflowOpen;
  bool get overflowOpen => _overflowOpen;
  set overflowOpen(bool value) {
    if (value == overflowOpen) {
      return;
    }
    _overflowOpen = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value == textDirection) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  // StoryPad: see _TextSelectionToolbarTrailingEdgeAlign.
  bool _isAbove = true;
  set isAbove(bool value) {
    if (value == _isAbove) return;
    _isAbove = value;
    markNeedsLayout();
  }

  _OverflowMetrics metrics = _OverflowMetrics();

  double _minHeight = 0;
  set minHeight(double value) {
    if (value == _minHeight) return;
    _minHeight = value;
    markNeedsLayout();
  }

  bool _visible = true;
  set visible(bool value) {
    if (value == _visible) return;
    _visible = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    child!.layout(constraints.loosen(), parentUsesSize: true);

    // Save the width when the menu is closed. If the menu changes, this width
    // is invalid, so it's important that this RenderBox be recreated in that
    // case. Currently, this is achieved by providing a new key to
    // _TextSelectionToolbarTrailingEdgeAlign.
    if (!overflowOpen && _closedWidth == null) {
      _closedWidth = child!.size.width;
    }

    size = constraints.constrain(
      Size(
        // If the open menu is wider than the closed menu, just use its own width
        // and don't worry about aligning the trailing edges.
        // _closedWidth is used even when the menu is closed to allow it to
        // animate its size while keeping the same edge alignment.
        math.max(
          _closedWidth == null || child!.size.width > _closedWidth! ? child!.size.width : _closedWidth!,
          // StoryPad: the room, past the toolbar's own chrome (the child's size beyond the morph's).
          room.width,
        ),
        math.max(math.max(child!.size.height, room.height), _minHeight),
      ),
    );

    // Set the offset in the parent data such that the child will be aligned to
    // the trailing edge, depending on the text direction.
    // StoryPad: and to the edge facing its anchor.
    final ToolbarItemsParentData childParentData = child!.parentData! as ToolbarItemsParentData;
    childParentData.offset = Offset(
      textDirection == TextDirection.rtl ? 0.0 : size.width - child!.size.width,
      _isAbove ? size.height - child!.size.height : 0.0,
    );
  }

  // StoryPad: the room the closed toolbar and the open menu both fit in, with the toolbar's chrome.
  Size get room {
    if (!metrics.hasOverflow) return Size.zero;
    final Size childSize = child!.size;
    return Size(
      math.max(metrics.closedSize.width, metrics.openSize.width) + childSize.width - metrics.size.width,
      math.max(metrics.closedSize.height, metrics.openSize.height) + childSize.height - metrics.size.height,
    );
  }

  // Paint at the offset set in the parent data.
  @override
  void paint(PaintingContext context, Offset offset) {
    // StoryPad: not before its side is known.
    if (!_visible) return;
    final ToolbarItemsParentData childParentData = child!.parentData! as ToolbarItemsParentData;
    context.paintChild(child!, childParentData.offset + offset);
  }

  // Include the parent data offset in the hit test.
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (!_visible) return false;
    // The x, y parameters have the top left of the node's box as the origin.
    final ToolbarItemsParentData childParentData = child!.parentData! as ToolbarItemsParentData;
    return result.addWithPaintOffset(
      offset: childParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        assert(transformed == position - childParentData.offset);
        return child!.hitTest(result, position: transformed);
      },
    );
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ToolbarItemsParentData) {
      child.parentData = ToolbarItemsParentData();
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final ToolbarItemsParentData childParentData = child.parentData! as ToolbarItemsParentData;
    transform.translateByDouble(childParentData.offset.dx, childParentData.offset.dy, 0, 1);
    super.applyPaintTransform(child, transform);
  }
}

// Renders the menu items in the correct positions in the menu and its overflow
// submenu based on calculating which item would first overflow.
class _TextSelectionToolbarItemsLayout extends MultiChildRenderObjectWidget {
  const _TextSelectionToolbarItemsLayout({
    required this.isAbove,
    required this.overflowOpen,
    required this.textDirection,
    this.onLayout,
    required super.children,
  });

  final bool isAbove;
  final bool overflowOpen;
  final TextDirection textDirection;

  // StoryPad: told the last item that fits after each layout.
  final ValueSetter<int>? onLayout;

  @override
  _RenderTextSelectionToolbarItemsLayout createRenderObject(BuildContext context) {
    return _RenderTextSelectionToolbarItemsLayout(
      isAbove: isAbove,
      overflowOpen: overflowOpen,
      textDirection: textDirection,
    )..onLayout = onLayout;
  }

  @override
  void updateRenderObject(BuildContext context, _RenderTextSelectionToolbarItemsLayout renderObject) {
    renderObject
      ..isAbove = isAbove
      ..textDirection = textDirection
      ..overflowOpen = overflowOpen
      ..onLayout = onLayout;
  }

  @override
  _TextSelectionToolbarItemsLayoutElement createElement() => _TextSelectionToolbarItemsLayoutElement(this);
}

class _TextSelectionToolbarItemsLayoutElement extends MultiChildRenderObjectElement {
  _TextSelectionToolbarItemsLayoutElement(super.widget);

  static bool _shouldPaint(Element child) {
    return (child.renderObject!.parentData! as ToolbarItemsParentData).shouldPaint;
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children.where(_shouldPaint).forEach(visitor);
  }
}

class _RenderTextSelectionToolbarItemsLayout extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, ToolbarItemsParentData> {
  _RenderTextSelectionToolbarItemsLayout({
    required bool isAbove,
    required bool overflowOpen,
    required TextDirection textDirection,
  }) : _isAbove = isAbove,
       _overflowOpen = overflowOpen,
       _textDirection = textDirection,
       super();

  // The index of the last item that doesn't overflow.
  int _lastIndexThatFits = -1;

  // StoryPad: see _TextSelectionToolbarItemsLayout.onLayout.
  ValueSetter<int>? onLayout;

  bool _isAbove;
  bool get isAbove => _isAbove;
  set isAbove(bool value) {
    if (value == isAbove) {
      return;
    }
    _isAbove = value;
    markNeedsLayout();
  }

  bool _overflowOpen;
  bool get overflowOpen => _overflowOpen;
  set overflowOpen(bool value) {
    if (value == overflowOpen) {
      return;
    }
    _overflowOpen = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value == textDirection) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  // Layout the necessary children, and figure out where the children first
  // overflow, if at all.
  void _layoutChildren() {
    // When overflow is not open, the toolbar is always a specific height.
    final BoxConstraints sizedConstraints = _overflowOpen
        ? constraints
        : BoxConstraints.loose(Size(constraints.maxWidth, _kToolbarHeight));

    int i = -1;
    double width = 0.0;
    visitChildren((RenderObject renderObjectChild) {
      i++;

      // No need to layout children inside the overflow menu when it's closed.
      // The opposite is not true. It is necessary to layout the children that
      // don't overflow when the overflow menu is open in order to calculate
      // _lastIndexThatFits.
      if (_lastIndexThatFits != -1 && !overflowOpen) {
        return;
      }

      final RenderBox child = renderObjectChild as RenderBox;
      child.layout(sizedConstraints.loosen(), parentUsesSize: true);
      width += child.size.width;

      if (width > sizedConstraints.maxWidth && _lastIndexThatFits == -1) {
        _lastIndexThatFits = i - 1;
      }
    });

    // If the last child overflows, but only because of the width of the
    // overflow button, then just show it and hide the overflow button.
    final RenderBox navButton = firstChild!;
    if (_lastIndexThatFits != -1 &&
        _lastIndexThatFits == childCount - 2 &&
        width - navButton.size.width <= sizedConstraints.maxWidth) {
      _lastIndexThatFits = -1;
    }
  }

  // Returns true when the child should be painted, false otherwise.
  bool _shouldPaintChild(RenderObject renderObjectChild, int index) {
    // Paint the navButton when there is overflow.
    if (renderObjectChild == firstChild) {
      return _lastIndexThatFits != -1;
    }

    // If there is no overflow, all children besides the navButton are painted.
    if (_lastIndexThatFits == -1) {
      return true;
    }

    // When there is overflow, paint if the child is in the part of the menu
    // that is currently open. Overflowing children are painted when the
    // overflow menu is open, and the children that fit are painted when the
    // overflow menu is closed.
    return (index > _lastIndexThatFits) == overflowOpen;
  }

  /// Horizontal layout.
  Size _placeChildrenHorizontally() {
    final RenderBox navButton = firstChild!;
    final bool isRtl = textDirection == TextDirection.rtl;

    final List<RenderBox> contentItems = <RenderBox>[];

    double totalWidth = 0.0;
    double maxHeight = 0.0;

    // First pass: calculate dimensions and collect items.
    int i = -1;
    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData = child.parentData! as ToolbarItemsParentData;
      i++;

      if (!_shouldPaintChild(child, i)) {
        // There is no need to update children that won't be painted.
        childParentData.shouldPaint = false;
      } else {
        childParentData.shouldPaint = true;

        totalWidth += child.size.width;
        maxHeight = math.max(maxHeight, child.size.height);

        if (child != navButton) {
          contentItems.add(child);
        }
      }
    });

    // Position items based on text direction.
    double currentX = 0.0;
    final bool showNavButton = _lastIndexThatFits >= 0;

    if (isRtl) {
      // In RTL, we want the nav button on the left and items right-aligned.
      if (showNavButton) {
        final ToolbarItemsParentData navParentData = navButton.parentData! as ToolbarItemsParentData;
        navParentData.offset = Offset.zero;
        currentX += navButton.size.width;
      }

      // Position content items from right to left.
      double rightEdge = totalWidth;
      for (final RenderBox item in contentItems) {
        rightEdge -= item.size.width;
        final ToolbarItemsParentData itemParentData = item.parentData! as ToolbarItemsParentData;
        itemParentData.offset = Offset(rightEdge, 0.0);
      }
    } else {
      // LTR: Place content items first, then nav button.
      // First position all content items from left to right.
      for (final RenderBox item in contentItems) {
        final ToolbarItemsParentData itemParentData = item.parentData! as ToolbarItemsParentData;
        itemParentData.offset = Offset(currentX, 0.0);
        currentX += item.size.width;
      }

      // Then place the nav button at the end.
      if (showNavButton) {
        final ToolbarItemsParentData navParentData = navButton.parentData! as ToolbarItemsParentData;
        navParentData.offset = Offset(currentX, 0.0);
      }
    }

    return Size(totalWidth, maxHeight);
  }

  /// Vertical layout (overflow menu).
  Size _placeChildrenVertically() {
    final RenderBox navButton = firstChild!;

    double currentY = 0.0;
    double maxWidth = 0.0;

    final ToolbarItemsParentData navButtonParentData = navButton.parentData! as ToolbarItemsParentData;

    if (_shouldPaintChild(navButton, 0)) {
      navButtonParentData.shouldPaint = true;
      if (!isAbove) {
        navButtonParentData.offset = Offset.zero;
        currentY += navButton.size.height;
        maxWidth = math.max(maxWidth, navButton.size.width);
      }
    } else {
      navButtonParentData.shouldPaint = false;
    }

    int i = -1;
    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData = child.parentData! as ToolbarItemsParentData;

      i++;

      // Ignore the navigation button.
      if (renderObjectChild == navButton) {
        return;
      }

      // There is no need to update children that won't be painted.
      if (!_shouldPaintChild(child, i)) {
        childParentData.shouldPaint = false;
        return;
      }

      childParentData.shouldPaint = true;
      childParentData.offset = Offset(0.0, currentY);
      currentY += child.size.height;
      maxWidth = math.max(maxWidth, child.size.width);
    });

    if (isAbove && navButtonParentData.shouldPaint) {
      navButtonParentData.offset = Offset(0.0, currentY);
      currentY += navButton.size.height;
      maxWidth = math.max(maxWidth, navButton.size.width);
    }

    maxWidth += 20;

    return Size(maxWidth, currentY);
  }

  // Decide which children will be painted, set their shouldPaint, and set the
  // offset that painted children will be placed at.
  void _placeChildren() {
    size = overflowOpen ? _placeChildrenVertically() : _placeChildrenHorizontally();
  }

  // Horizontally expand the children when the menu overflows so they can react to
  // pointer events into their whole area.
  void _resizeChildrenWhenOverflow() {
    if (!overflowOpen) {
      return;
    }

    final RenderBox navButton = firstChild!;
    int i = -1;

    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData = child.parentData! as ToolbarItemsParentData;

      i++;

      // Ignore the navigation button.
      if (renderObjectChild == navButton) {
        return;
      }

      // There is no need to update children that won't be painted.
      if (!_shouldPaintChild(renderObjectChild, i)) {
        childParentData.shouldPaint = false;
        return;
      }

      child.layout(BoxConstraints.tightFor(width: size.width), parentUsesSize: true);
    });
  }

  @override
  void performLayout() {
    _lastIndexThatFits = -1;
    if (firstChild == null) {
      size = constraints.smallest;
      return;
    }

    _layoutChildren();
    _placeChildren();
    _resizeChildrenWhenOverflow();
    onLayout?.call(_lastIndexThatFits);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData = child.parentData! as ToolbarItemsParentData;
      if (!childParentData.shouldPaint) {
        return;
      }

      context.paintChild(child, childParentData.offset + offset);
    });
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ToolbarItemsParentData) {
      child.parentData = ToolbarItemsParentData();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      // The x, y parameters have the top left of the node's box as the origin.
      final ToolbarItemsParentData childParentData = child.parentData! as ToolbarItemsParentData;

      // Don't hit test children aren't shown.
      if (!childParentData.shouldPaint) {
        child = childParentData.previousSibling;
        continue;
      }

      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
      child = childParentData.previousSibling;
    }
    return false;
  }

  // Visit only the children that should be painted.
  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData = child.parentData! as ToolbarItemsParentData;
      if (childParentData.shouldPaint) {
        visitor(renderObjectChild);
      }
    });
  }
}

// A button styled like a Material native Android text selection overflow menu
// forward and back controls.
class _TextSelectionToolbarOverflowButton extends StatelessWidget {
  const _TextSelectionToolbarOverflowButton({super.key, required this.icon, this.onPressed, this.tooltip});

  // StoryPad: any widget (upstream: an Icon), for the animated one.
  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.card,
      color: const Color(0x00000000),
      child: IconButton(
        // TODO(justinmc): This should be an AnimatedIcon, but
        // AnimatedIcons doesn't yet support arrow_back to more_vert.
        // https://github.com/flutter/flutter/issues/51209
        icon: icon,
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

// StoryPad: reports its child's intrinsic widths [extra] wider, so an [IntrinsicWidth] above sizes the child that
// much wider than its widest content.
class _ExtraIntrinsicWidth extends SingleChildRenderObjectWidget {
  const _ExtraIntrinsicWidth({required this.extra, required super.child});

  final double extra;

  @override
  _RenderExtraIntrinsicWidth createRenderObject(BuildContext context) => _RenderExtraIntrinsicWidth(extra);

  @override
  void updateRenderObject(BuildContext context, _RenderExtraIntrinsicWidth renderObject) {
    renderObject.extra = extra;
  }
}

class _RenderExtraIntrinsicWidth extends RenderProxyBox {
  _RenderExtraIntrinsicWidth(this._extra);

  double _extra;
  set extra(double value) {
    if (value == _extra) {
      return;
    }
    _extra = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) => super.computeMinIntrinsicWidth(height) + _extra;

  @override
  double computeMaxIntrinsicWidth(double height) => super.computeMaxIntrinsicWidth(height) + _extra;
}

// StoryPad: what _RenderOverflowMorph's last layout found, for the room _TextSelectionToolbarTrailingEdgeAlign takes.
class _OverflowMetrics {
  // The morph's own (animating) size.
  Size size = Size.zero;
  Size closedSize = Size.zero;
  Size openSize = Size.zero;
  bool hasOverflow = false;
}
