part of 'side_items.dart';

abstract class BaseSideItem {
  Widget build(
    BuildContext context, {
    bool fromSideBar = false,
    bool fromEndDrawer = false,
  });
}
