part of 'backups_view.dart';

class _BackupsContent extends StatelessWidget {
  const _BackupsContent(this.viewModel);

  final BackupsViewModel viewModel;

  final double avatarSize = 56;

  @override
  Widget build(BuildContext context) {
    final BackupProvider provider = Provider.of<BackupProvider>(context);

    return SpDefaultScrollController(builder: (context, controller) {
      return Scaffold(
        appBar: AppBar(
          title: Text(tr('page.backups.title')),
          actions: [
            IconButton(
              tooltip: tr('page.offline_backup.title'),
              icon: Icon(Icons.folder_open),
              onPressed: () {
                OfflineBackupsRoute().push(context);
              },
            ),
          ],
        ),
        body: Stack(children: [
          if (viewModel.hasData) _TimelineDivider(avatarSize: avatarSize, context: context),
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
    return SliverPadding(
      padding: EdgeInsets.all(16.0),
      sliver: SliverToBoxAdapter(
        child: Text(tr("general.no_backup_found")),
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
    final menus = getGroupMenus(context, file);

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
                    _BackupTileMonogram(context: context, fileInfo: fileInfo, previousFileInfo: previousFileInfo),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero.copyWith(right: 16.0),
                        title: Text(fileInfo?.device.model ?? tr("general.unknown")),
                        subtitle: Text(
                          DateFormatHelper.yMEd_jmNullable(fileInfo?.createdAt, context.locale) ?? tr("general.na"),
                        ),
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

  List<SpPopMenuItem> getGroupMenus(BuildContext context, CloudFileObject file) {
    return [
      SpPopMenuItem(
        title: tr("button.view"),
        leadingIconData: Icons.info,
        onPressed: () => viewModel.openCloudFile(context, file),
      ),
      SpPopMenuItem(
        title: tr("button.delete"),
        leadingIconData: Icons.delete,
        titleStyle: TextStyle(color: ColorScheme.of(context).error),
        onPressed: () async {
          OkCancelResult userResponse = await showOkCancelAlertDialog(
            context: context,
            title: tr("dialog.are_you_sure_to_delete_this_backup.title"),
            message: tr("dialog.are_you_sure_to_delete_this_backup.message"),
            isDestructiveAction: true,
            okLabel: tr("button.delete"),
          );

          if (userResponse == OkCancelResult.ok && context.mounted) {
            await viewModel.deleteCloudFile(context, file);
          }
        },
      ),
    ];
  }
}
