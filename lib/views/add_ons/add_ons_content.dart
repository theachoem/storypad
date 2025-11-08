part of 'add_ons_view.dart';

class _AddOnsContent extends StatelessWidget {
  const _AddOnsContent(this.viewModel);

  final AddOnsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('page.add_ons.title')),
        centerTitle: kIsCupertino,
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        actions: [
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
        ],
      ),
      body: buildBody(context),
      bottomNavigationBar: buildBottomNavigation(context),
    );
  }

  Widget buildBody(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    if (viewModel.addOns == null) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 12.0),
        if (viewModel.dealEndDate != null) buildOfferDealCard(viewModel.dealEndDate!, padding, context),
        buildAddOnsGrid(context, padding),
      ],
    );
  }

  Widget buildOfferDealCard(DateTime dealEndDate, EdgeInsets padding, BuildContext context) {
    String? message;
    IconData? leadingIcon;
    MaterialColor? baseColor;

    if (dealEndDate.isAfter(DateTime.now().add(const Duration(days: 7)))) {
      message = 'Limited-time offers until ${DateFormatHelper.yMMMd(dealEndDate, context.locale)}';
      leadingIcon = SpIcons.tag;
      baseColor = Colors.orange;
    } else if (dealEndDate.isAfter(DateTime.now().add(const Duration(days: 3)))) {
      message = 'Hurry! Offers ending ${DateFormatHelper.yMMMd(dealEndDate, context.locale)}';
      leadingIcon = SpIcons.tag;
      baseColor = Colors.deepOrange;
    } else if (dealEndDate.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      message = 'Final call! Deals expire ${DateFormatHelper.yMMMd(dealEndDate, context.locale)}';
      leadingIcon = SpIcons.alarm;
      baseColor = Colors.red;
    } else if (dealEndDate.isAfter(DateTime.now())) {
      message = 'Last chance! Offers end TODAY';
      leadingIcon = SpIcons.alarm;
      baseColor = Colors.red;
    } else {
      message = null;
      leadingIcon = null;
      baseColor = null;
    }

    if (message == null || leadingIcon == null || baseColor == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(
        left: padding.left + 16.0,
        right: padding.right + 16.0,
        bottom: 12.0,
      ),
      padding: const EdgeInsets.only(top: 1),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: !AppTheme.isDarkMode(context) ? baseColor.shade700 : baseColor.shade300,
          radius: 11.0,
          dashWidth: 6.0,
          dashSpace: 3.0,
          strokeWidth: 1,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8.0,
            children: [
              SpLoopAnimationBuilder(
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: lerpDouble(1, 0.9, value),
                    child: child!,
                  );
                },
                child: Icon(
                  leadingIcon,
                  size: 16.0,
                  color: !AppTheme.isDarkMode(context) ? baseColor.shade900 : baseColor.shade300,
                ),
              ),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: !AppTheme.isDarkMode(context) ? baseColor.shade900 : baseColor.shade300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAddOnsGrid(BuildContext context, EdgeInsets screenPadding) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    final isMediumScreen = screenWidth > 600;

    int crossAxisCount = isLargeScreen ? 4 : (isMediumScreen ? 3 : 2);

    return AlignedGridView.count(
      padding: EdgeInsets.only(
        left: screenPadding.left + 16.0,
        right: screenPadding.right + 16.0,
        bottom: 0,
        top: 0,
      ),
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12.0,
      crossAxisSpacing: 12.0,
      itemCount: viewModel.addOns!.length,
      itemBuilder: (context, index) {
        final addOn = viewModel.addOns![index];
        return _AddOnGridItem(
          addOn: addOn,
          onTap: () => ShowAddOnRoute(
            addOn: addOn,
            fullscreenDialog: viewModel.params.fullscreenDialog,
          ).push(context),
        );
      },
    );
  }

  Widget buildRewardsCard() {
    return Consumer<InAppPurchaseProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0).add(
            EdgeInsets.only(
              left: MediaQuery.of(context).padding.left,
              right: MediaQuery.of(context).padding.right,
            ),
          ),
          child: ListTile(
            visualDensity: VisualDensity.compact,
            dense: true,
            key: ValueKey(provider.rewardExpiredAt != null ? 'appied' : 'not_applied'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
            leading: const SpGiftAnimatedIcon(),
            title: Text(
              provider.rewardExpiredAt != null
                  ? tr('list_tile.unlock_your_rewards.applied_title')
                  : tr('list_tile.unlock_your_rewards.unapplied_title'),
            ),
            trailing: const Icon(SpIcons.info, size: 20),
            subtitle: provider.rewardExpiredAt != null
                ? Text(
                    tr(
                      'general.expired_on',
                      namedArgs: {'EXP_DATE': DateFormatHelper.yMEd(provider.rewardExpiredAt!, context.locale)},
                    ),
                  )
                : null,
            onTap: () => SpRewardSheet().show(context: context),
          ),
        );
      },
    );
  }

  Widget buildBottomNavigation(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (kIAPEnabled) buildRewardsCard(),
        Container(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 8.0,
            bottom: MediaQuery.of(context).padding.bottom + 16.0,
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children:
                [
                  (
                    (tr('general.term_of_use')),
                    () => UrlOpenerService.openInCustomTab(context, 'https://storypad.me/term-of-use'),
                  ),
                  ("•", null),
                  (
                    (tr('general.privacy_policy')),
                    () => UrlOpenerService.openInCustomTab(context, 'https://storypad.me/privacy-policy'),
                  ),
                  ("•", null),
                  (
                    tr('button.restore_purchase'),
                    () => context.read<InAppPurchaseProvider>().restorePurchase(context),
                  ),
                ].map((link) {
                  return SpTapEffect(
                    onTap: link.$2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8),
                      child: Text(
                        link.$1,
                        style: TextTheme.of(context).labelMedium?.copyWith(color: ColorScheme.of(context).primary),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = _createDashedRRect(size, radius, dashWidth, dashSpace);
    canvas.drawPath(path, paint);
  }

  Path _createDashedRRect(Size size, double radius, double dashW, double dashS) {
    final path = Path();
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrectPath = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    final metrics = rrectPath.computeMetrics();
    double distance = 0;
    bool isDash = true;

    for (final metric in metrics) {
      distance = 0;
      isDash = true;

      while (distance < metric.length) {
        final segmentLength = isDash ? dashW : dashS;
        final nextDistance = (distance + segmentLength).clamp(0.0, metric.length);
        final tangent = metric.getTangentForOffset(distance);

        if (tangent != null) {
          path.moveTo(tangent.position.dx, tangent.position.dy);
        }

        final nextTangent = metric.getTangentForOffset(nextDistance);
        if (nextTangent != null && isDash) {
          path.lineTo(nextTangent.position.dx, nextTangent.position.dy);
        }

        distance = nextDistance;
        isDash = !isDash;
      }
    }

    return path;
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
