part of 'side_items.dart';

class IconButtonSideItem extends BaseSideItem {
  final String title;
  final BaseRoute route;
  final IconData iconData;
  final IconData selectedIconData;
  final void Function(BuildContext, BaseRoute route)? onTap;

  IconButtonSideItem({
    required this.title,
    required this.route,
    required this.iconData,
    required this.selectedIconData,
    required this.onTap,
  });
}

class ListTileSideItem extends BaseSideItem {
  final String title;
  final String? subtitle;
  final Widget icon;
  final void Function(BuildContext) onTap;

  ListTileSideItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class CustomSideItem extends BaseSideItem {
  final Widget Function(BuildContext context) builder;

  CustomSideItem({
    required this.builder,
  });

  static BaseSideItem divider({double? height}) => CustomSideItem(builder: (context) => const Divider());

  static BaseSideItem custom({
    required Widget Function(BuildContext) builder,
  }) => CustomSideItem(builder: (context) => builder(context));
}

abstract class BaseSideItem {}
