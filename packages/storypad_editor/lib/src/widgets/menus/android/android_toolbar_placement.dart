import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Which side of the selection the Android toolbar goes, and how many items its open ⋮ menu shows -- as native
/// decides it when the toolbar shows (`refreshCoordinatesAndOverflowDirection`), within what the hosts here can do.
@immutable
final class AndroidToolbarPlacement {
  const AndroidToolbarPlacement({required this.isAbove, required this.overflowItems, required this.hintsMore});

  final bool isAbove;

  /// The open menu's items shown before it scrolls.
  final int overflowItems;

  /// Whether half of one more shows below them (there are more).
  final bool hintsMore;

  /// The open menu's list height, past its back button.
  double get listHeight => overflowItems * _lineHeight + (hintsMore ? _lineHeight / 2 : 0);

  @override
  bool operator ==(Object other) =>
      other is AndroidToolbarPlacement &&
      other.isAbove == isAbove &&
      other.overflowItems == overflowItems &&
      other.hintsMore == hintsMore;

  @override
  int get hashCode => Object.hash(isAbove, overflowItems, hintsMore);

  @override
  String toString() => 'AndroidToolbarPlacement(isAbove: $isAbove, items: $overflowItems, hintsMore: $hintsMore)';

  // Native Android's floating text toolbar (AOSP frameworks/base
  // core/java/com/android/internal/widget/floatingtoolbar/LocalFloatingToolbarPopup.java): one item's height
  // (floating_toolbar_height), the ⋮/back button's, and the toolbar's margin from the screen edge and the text
  // (floating_toolbar_vertical_margin), in dp.
  static const double _lineHeight = 48;

  static const double _buttonHeight = 48;

  static const double _margin = 8;

  // The open ⋮ menu: 2 to 4 items, and half of one more when there are more (a hint that it scrolls).
  static const int _minOverflowItems = 2;

  static const int _maxOverflowItems = 4;

  /// Native's `calculateOverflowHeight(maxItemSize)`, as a placement on [isAbove]'s side.
  static AndroidToolbarPlacement _overflow(bool isAbove, int maxItems, int count) {
    final int items = math.min(_maxOverflowItems, math.min(math.max(_minOverflowItems, maxItems), count));
    return AndroidToolbarPlacement(isAbove: isAbove, overflowItems: items, hintsMore: items < count);
  }

  /// Native's `updateOverflowHeight(suggestedHeight)`: as many items as fit in [height], past the back button. Native
  /// lets the half item hinting at more run past [height]; the hosts here would then put the toolbar on the other side,
  /// so one fewer shows instead (down to native's two).
  static AndroidToolbarPlacement _fitting(bool isAbove, double height, int count) {
    int maxItems = ((height - _buttonHeight) / _lineHeight).floor();
    AndroidToolbarPlacement placement = _overflow(isAbove, maxItems, count);
    while (placement.listHeight + _buttonHeight > height && placement.overflowItems > _minOverflowItems) {
      placement = _overflow(isAbove, --maxItems, count);
    }
    return placement;
  }

  /// Places an Android toolbar with an [overflowCount]-item ⋮ menu for [selection], within [viewport] (the screen past
  /// the status bar, navigation bar and keyboard; all in global logical pixels), the way native does with an overflow:
  ///
  /// 1. Room above the selection for the open menu: above, opening upwards, shrunk to the room.
  /// 2. Room above for the toolbar only, and for the menu opening downwards from there over the selection: native
  ///    keeps the toolbar above and opens the menu over the text.
  /// 3. Room below for the open menu: below, opening downwards, shrunk to the room.
  /// 4. Room below for the toolbar only: native keeps it below and opens the menu upwards over the text.
  /// 5. No room: native pins it to the top of the screen, opening downwards.
  ///
  /// The hosts here (super_editor's aligner, the reader's position delegate) only place a toolbar right above or right
  /// below the selection, growing away from it -- so 2 is placed as 3 when there's room below for it, and otherwise 2,
  /// 4 and 5 go to whichever side has more room, shrunk to it.
  ///
  /// [gapAbove] and [gapBelow] are how far the host puts the toolbar from the selection (native: its 8dp margin); the
  /// rooms are measured from there, keeping native's margin from the screen edge. With [side], the placement on that
  /// side, as tall as its room allows (for when the host put the toolbar there regardless).
  static AndroidToolbarPlacement place({
    required Rect selection,
    required Rect viewport,
    required int overflowCount,
    double gapAbove = _margin,
    double gapBelow = _margin,
    bool? side,
  }) {
    // As native measures it (refreshCoordinatesAndOverflowDirection), to pick the case.
    final double availableAbove = selection.top - viewport.top;
    final double availableBelow = viewport.bottom - selection.bottom;
    const double margin = 2 * _margin;
    const double toolbarHeightWithMargin = _lineHeight + margin;
    final double minimumOverflowHeightWithMargin = _overflowHeight(_minOverflowItems, overflowCount) + margin;
    final double availableThroughContentDown = viewport.bottom - selection.top + toolbarHeightWithMargin;

    // The room the open menu has on each side, from where the host puts the toolbar.
    final double roomAbove = selection.top - gapAbove - viewport.top - _margin;
    final double roomBelow = viewport.bottom - selection.bottom - gapBelow - _margin;
    AndroidToolbarPlacement above() => _fitting(true, roomAbove, overflowCount);
    AndroidToolbarPlacement below() => _fitting(false, roomBelow, overflowCount);
    AndroidToolbarPlacement roomier() => roomAbove >= roomBelow ? above() : below();

    if (side != null) return side ? above() : below();

    if (availableAbove >= minimumOverflowHeightWithMargin) return above(); // 1
    if (availableAbove >= toolbarHeightWithMargin && availableThroughContentDown >= minimumOverflowHeightWithMargin) {
      return availableBelow >= minimumOverflowHeightWithMargin ? below() : roomier(); // 2
    }
    if (availableBelow >= minimumOverflowHeightWithMargin) return below(); // 3
    return roomier(); // 4, 5
  }

  /// Native's `calculateOverflowHeight`: the open menu's height with its back button.
  static double _overflowHeight(int maxItems, int count) {
    final AndroidToolbarPlacement placement = _overflow(true, maxItems, count);
    return placement.listHeight + _buttonHeight;
  }
}
