part of 'backup_view.dart';

class _BackupContent extends StatelessWidget {
  const _BackupContent(this.viewModel);

  final BackupViewModel viewModel;

  final double avatarSize = 56;

  @override
  Widget build(BuildContext context) {
    final BackupProvider provider = Provider.of<BackupProvider>(context);

    return SpDefaultScrollController(builder: (context, controller) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Backups"),
          actions: [
            IconButton(
              tooltip: "Offline Backup",
              icon: Icon(Icons.folder_open),
              onPressed: () {
                OfflineBackupRoute().push(context);
              },
            ),
          ],
        ),
        body: Stack(children: [
          if (viewModel.hasData) buildTimelineDivider(context),
          RefreshIndicator.adaptive(
            onRefresh: () => viewModel.load(context),
            child: CustomScrollView(
              controller: controller,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                buildSliverProfileTile(provider),
                if (viewModel.loading) ...[
                  buildSliverLoading()
                ] else if (viewModel.hasData) ...[
                  buildSliverBackupList(context)
                ] else ...[
                  buildSliverEmpty()
                ]
              ],
            ),
          ),
        ]),
      );
    });
  }

  SliverToBoxAdapter buildSliverProfileTile(BackupProvider provider) {
    return SliverToBoxAdapter(
      child: UserProfileCollapsibleTile(
        viewModel: viewModel,
        source: provider.source,
        avatarSize: avatarSize,
      ),
    );
  }

  SliverPadding buildSliverEmpty() {
    return const SliverPadding(
      padding: EdgeInsets.all(16.0),
      sliver: SliverToBoxAdapter(
        child: Text("No backups found."),
      ),
    );
  }

  SliverPadding buildSliverLoading() {
    return const SliverPadding(
      padding: EdgeInsets.all(16.0),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      ),
    );
  }

  SliverPadding buildSliverBackupList(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16.0, top: 8.0),
      sliver: SliverList.builder(
        itemCount: viewModel.files?.length ?? 0,
        itemBuilder: (context, index) {
          return buildBackupGroup(context, index);
        },
      ),
    );
  }

  Widget buildBackupGroup(BuildContext context, int index) {
    final previousFile = index - 1 >= 0 ? viewModel.files![index - 1] : null;
    final file = viewModel.files![index];

    final previousFileInfo = previousFile?.getFileInfo();
    final fileInfo = file.getFileInfo();

    final menus = [
      SpPopMenuItem(
        title: 'View',
        leadingIconData: Icons.info,
        onPressed: () => viewModel.openCloudFile(context, file),
      ),
      SpPopMenuItem(
        title: 'Delete',
        leadingIconData: Icons.delete,
        titleStyle: TextStyle(color: ColorScheme.of(context).error),
        onPressed: () async {
          OkCancelResult userResponse = await showOkCancelAlertDialog(
            context: context,
            title: "Are you sure to delete this backup?",
            message: "You can't undo this action.",
            isDestructiveAction: true,
            okLabel: "Delete",
          );

          if (userResponse == OkCancelResult.ok && context.mounted) {
            await viewModel.deleteCloudFile(context, file);
          }
        },
      ),
    ];

    return Theme(
      // Remove theme wrapper here when this is fixed:
      // https://github.com/letsar/flutter_slidable/issues/512
      data: Theme.of(context).copyWith(
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(iconColor: WidgetStatePropertyAll(ColorScheme.of(context).onPrimary)),
        ),
      ),
      child: Slidable(
        closeOnScroll: true,
        key: ValueKey(file.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: List.generate(menus.length, (index) {
            final menu = menus[index];
            return SlidableAction(
              icon: menu.leadingIconData,
              backgroundColor: menu.titleStyle?.color ?? ColorFromDayService(context: context).get(index + 1)!,
              foregroundColor: ColorScheme.of(context).onPrimary,
              onPressed: (context) => menu.onPressed?.call(),
            );
          }),
        ),
        child: SpPopupMenuButton(
          smartDx: true,
          dyGetter: (dy) => dy + 36,
          items: (BuildContext context) => menus,
          builder: (callback) {
            return InkWell(
              onTap: callback,
              onLongPress: callback,
              child: Container(
                padding: EdgeInsets.only(
                  right: AppTheme.getDirectionValue(context, (avatarSize + 12) / 2 - 32 / 2.0, 0.0)!,
                  left: AppTheme.getDirectionValue(context, 0.0, (avatarSize + 12) / 2 - 32 / 2.0)!,
                ),
                child: Row(
                  spacing: 16.0,
                  children: [
                    buildMonogram(context, fileInfo, previousFileInfo),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero.copyWith(right: 16.0),
                        title: Text(fileInfo?.device.model ?? 'Unknown'),
                        subtitle: Text(DateFormatService.yMEd_jmNullable(fileInfo?.createdAt) ?? 'N/A'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildTimelineDivider(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: AppTheme.getDirectionValue(context, null, (avatarSize + 12) / 2),
      right: AppTheme.getDirectionValue(context, (avatarSize + 12) / 2, null),
      child: const VerticalDivider(
        width: 1,
        indent: 0.0,
      ),
    );
  }

  Widget buildMonogram(BuildContext context, BackupFileObject? fileInfo, BackupFileObject? previousFileInfo) {
    double monogramSize = 32;

    bool showMonogram = true;
    if (fileInfo == null) {
      showMonogram = false;
    } else if (previousFileInfo != null) {
      showMonogram = !previousFileInfo.sameDayAs(fileInfo);
    }

    if (!showMonogram) {
      return Container(
        width: monogramSize,
        margin: const EdgeInsets.only(top: 9.0, left: 0.5),
        alignment: Alignment.center,
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: ColorScheme.of(context).onSurface,
          ),
        ),
      );
    }

    final date = fileInfo!.createdAt;

    return Column(
      spacing: 4.0,
      children: [
        Container(
          width: monogramSize,
          color: ColorScheme.of(context).surface.withValues(),
          child: Text(
            DateFormatService.E(date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextTheme.of(context).labelMedium,
          ),
        ),
        Container(
          width: monogramSize,
          height: monogramSize,
          decoration: BoxDecoration(
            color: ColorFromDayService(context: context).get(date.weekday),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            date.day.toString(),
            style: TextTheme.of(context).bodyMedium?.copyWith(color: ColorScheme.of(context).onPrimary),
          ),
        ),
      ],
    );
  }
}
