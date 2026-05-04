part of 'storage_management_view.dart';

class _StorageManagementContent extends StatelessWidget {
  const _StorageManagementContent(this.viewModel);

  final StorageManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Management'),
        bottom: (viewModel.loading || viewModel.reloading)
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () => viewModel.reload(context),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            _buildLocalSection(context),
            if (viewModel.cloudQuotas.isNotEmpty) ...[
              const Divider(),
              _buildCloudSection(context),
            ],
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SpSectionTitle(title: "Local Storage"),
        _buildLocalTile(
          context,
          icon: SpIcons.photo,
          label: "Images & Audio",
          paths: [SupportDirectoryPath.images, SupportDirectoryPath.audio],
        ),
        _buildLocalTile(
          context,
          icon: SpIcons.import,
          label: "Backups & Database",
          paths: [SupportDirectoryPath.backups, SupportDirectoryPath.objectbox],
        ),
        _buildCacheFilesTile(
          context,
          icon: SpIcons.file,
          label: 'Cache files',
        ),
        ListTile(
          dense: true,
          title: Text(
            "Total",
            style: TextTheme.of(context).bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Text(
            _formatBytes(viewModel.totalLocalBytes),
            style: TextTheme.of(context).bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<SupportDirectoryPath> paths,
  }) {
    final size = paths.fold<int>(0, (a, p) => a + (viewModel.localSizes[p] ?? 0));
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(_formatBytes(size)),
    );
  }

  Widget _buildCacheFilesTile(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final size = viewModel.cacheFilesBytes;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: .end,
        children: [
          if (size > 0) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => viewModel.clearCacheFiles(context),
              icon: const Icon(SpIcons.delete),
              label: const Text('Clear'),
            ),
          ],
          Text(_formatBytes(size)),
        ],
      ),
    );
  }

  Widget _buildCloudSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SpSectionTitle(title: 'Cloud Storage'),
        for (final entry in viewModel.cloudQuotas.entries) _buildCloudTile(context, entry.key, entry.value),
      ],
    );
  }

  Widget _buildCloudTile(
    BuildContext context,
    BackupServiceType serviceType,
    CloudStorageQuotaObject? quota,
  ) {
    final provider = context.read<BackupProvider>();
    final email = provider.currentGoogleUser?.email;

    if (quota == null) {
      return ListTile(
        leading: Icon(serviceType.icon),
        title: Text(serviceType.displayName),
        subtitle: const Text('N/A'),
      );
    }

    final appUsageBytes = quota.appUsageInBytes;
    final accountUsageBytes = quota.accountUsageInBytes;
    final limitBytes = quota.limitInBytes;

    final appUsedLabel = _formatBytes(appUsageBytes);
    final accountUsedLabel = accountUsageBytes != null ? _formatBytes(accountUsageBytes) : 'N/A';
    final limitLabel = limitBytes != null ? _formatBytes(limitBytes) : 'N/A';

    final hasFullQuotaData = accountUsageBytes != null && limitBytes != null && limitBytes > 0;
    final otherUsageBytes = hasFullQuotaData ? (accountUsageBytes - appUsageBytes).clamp(0, accountUsageBytes) : 0;
    final freeBytes = hasFullQuotaData ? (limitBytes - accountUsageBytes).clamp(0, limitBytes) : 0;

    final appFraction = hasFullQuotaData ? (appUsageBytes / limitBytes).clamp(0.0, 1.0) : 0.0;
    final otherFraction = hasFullQuotaData ? (otherUsageBytes / limitBytes).clamp(0.0, 1.0) : 0.0;
    final usedFraction = (appFraction + otherFraction).clamp(0.0, 1.0);

    final appColor = ColorFromDayService(context: context).get(2)!;
    final otherColor = ColorFromDayService(context: context).get(1)!;
    final freeColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return ListTile(
      leading: Column(
        mainAxisAlignment: .center,
        children: [
          Icon(serviceType.icon),
        ],
      ),
      title: Text(serviceType.displayName),
      isThreeLine: true,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (email != null) Text(email, style: TextTheme.of(context).bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildColorPrefix(color: freeColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasFullQuotaData ? 'Free ${_formatBytes(freeBytes)} of $limitLabel' : 'Overall: $accountUsedLabel',
                  style: TextTheme.of(context).bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildColorPrefix(color: appColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'This app: $appUsedLabel',
                  style: TextTheme.of(context).bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildColorPrefix(color: otherColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Other apps: ${_formatBytes(otherUsageBytes)}',
                  style: TextTheme.of(context).bodySmall,
                ),
              ),
            ],
          ),
          if (hasFullQuotaData) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 10,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const minVisibleAppWidth = 2.0;

                    final barWidth = constraints.maxWidth;
                    final rawUsedWidth = (barWidth * usedFraction).clamp(0.0, barWidth).toDouble();
                    final rawAppWidth = (barWidth * appFraction).clamp(0.0, barWidth).toDouble();

                    // Tiny app usage may be sub-pixel; keep it visible while preserving total used width.
                    final appWidth = appFraction > 0
                        ? rawAppWidth.clamp(minVisibleAppWidth, rawUsedWidth > 0 ? rawUsedWidth : barWidth).toDouble()
                        : 0.0;
                    final otherWidth = (rawUsedWidth - appWidth).clamp(0.0, barWidth).toDouble();

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ColoredBox(color: freeColor),
                        ),
                        if (otherWidth > 0)
                          Positioned(
                            left: appWidth,
                            top: 0,
                            bottom: 0,
                            width: otherWidth,
                            child: ColoredBox(color: otherColor),
                          ),
                        if (appWidth > 0)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: appWidth,
                            child: ColoredBox(color: appColor),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColorPrefix({required Color color}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int i = 0;
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
  }
}
