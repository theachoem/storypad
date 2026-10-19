import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/src/widgets/menus/android/android_toolbar_placement.dart';

/// Native Android's placement of its text toolbar with a ⋮ menu (LocalFloatingToolbarPopup), within what the hosts
/// here can do.
void main() {
  // A 24-tall status bar; 8 from the selection, as native.
  const viewport = Rect.fromLTRB(0, 24, 400, 800);
  AndroidToolbarPlacement place(double top, {double height = 20, int count = 10, Rect area = viewport, bool? side}) =>
      AndroidToolbarPlacement.place(
        selection: Rect.fromLTWH(40, top, 100, height),
        viewport: area,
        overflowCount: count,
        side: side,
      );

  test('room above for the open menu: above, four items and half of a fifth', () {
    expect(place(500), const AndroidToolbarPlacement(isAbove: true, overflowItems: 4, hintsMore: true));
    expect(place(500).listHeight, 48 * 4.5);
  });

  test('less room above: the menu shrinks to it, down to two items (native\'s updateOverflowHeight)', () {
    // 224 - 24: 200 above, 184 of it the menu's room (8 from the selection, 8 from the status bar); less the back
    // button, two items.
    expect(place(224), const AndroidToolbarPlacement(isAbove: true, overflowItems: 2, hintsMore: true));
    // 232 of room: three items and the half one, with the button (216).
    expect(place(272), const AndroidToolbarPlacement(isAbove: true, overflowItems: 3, hintsMore: true));
    // 208: three items fit, not with the half one (native lets that run past the room; the hosts here would flip it).
    expect(place(248), const AndroidToolbarPlacement(isAbove: true, overflowItems: 2, hintsMore: true));
  });

  test('room above for the toolbar but not the menu: native opens it downwards over the text; here, below', () {
    expect(place(124), const AndroidToolbarPlacement(isAbove: false, overflowItems: 4, hintsMore: true));
  });

  test('no room above even for the toolbar: below', () {
    expect(place(50).isAbove, isFalse);
  });

  test('little room either side: the roomier one, at least two items (as native)', () {
    const short = Rect.fromLTRB(0, 24, 400, 300);
    final placement = place(40, height: 210, area: short);
    expect(placement, const AndroidToolbarPlacement(isAbove: false, overflowItems: 2, hintsMore: true));
  });

  test('few items: all of them, without the half hint', () {
    expect(place(500, count: 1), const AndroidToolbarPlacement(isAbove: true, overflowItems: 1, hintsMore: false));
    expect(place(500, count: 4), const AndroidToolbarPlacement(isAbove: true, overflowItems: 4, hintsMore: false));
  });

  test('a given side: the menu that fits there', () {
    expect(place(224, side: false), const AndroidToolbarPlacement(isAbove: false, overflowItems: 4, hintsMore: true));
  });

  test('the host\'s gaps count against the room', () {
    final placement = AndroidToolbarPlacement.place(
      selection: const Rect.fromLTWH(40, 272, 100, 20),
      viewport: viewport,
      overflowCount: 10,
      gapAbove: 56,
    );
    expect(placement.overflowItems, 2);
  });
}
