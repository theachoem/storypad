part of 'cloud_optimize_view.dart';

class _CloudOptimizeContent extends StatelessWidget {
  const _CloudOptimizeContent(this.viewModel);

  final CloudOptimizeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isAllDone = viewModel.currentStep == OptimizeStep.done;
    final green = ColorFromDayService(context: context).get(4)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Optimize ${viewModel.serviceType.displayName}'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _StepCard(
            stepNumber: 1,
            title: 'Sync latest data',
            currentStep: viewModel.currentStep,
            activeStep: OptimizeStep.syncing,
            doneSteps: const {
              OptimizeStep.fetchingFiles,
              OptimizeStep.analyzing,
              OptimizeStep.awaitingConfirmation,
              OptimizeStep.cleaningUp,
              OptimizeStep.done,
              OptimizeStep.error,
            },
            skipped:
                viewModel.currentStep != OptimizeStep.syncing &&
                viewModel.currentStep != OptimizeStep.idle &&
                !viewModel.syncSucceeded,
            doneSubtitle: viewModel.syncSucceeded ? 'Sync complete' : 'Sync skipped',
            activeSubtitle: 'Syncing with ${viewModel.serviceType.displayName}\u2026',
            doneColor: isAllDone ? green : null,
          ),
          _StepCard(
            stepNumber: 2,
            title: 'Fetch cloud files',
            currentStep: viewModel.currentStep,
            activeStep: OptimizeStep.fetchingFiles,
            doneSteps: const {
              OptimizeStep.analyzing,
              OptimizeStep.awaitingConfirmation,
              OptimizeStep.cleaningUp,
              OptimizeStep.done,
              OptimizeStep.error,
            },
            doneSubtitle: '${viewModel.fetchedFilesCount} file${viewModel.fetchedFilesCount == 1 ? '' : 's'} found',
            activeSubtitle: 'Scanning images and audio folders\u2026',
            doneColor: isAllDone ? green : null,
          ),
          _StepCard(
            stepNumber: 3,
            title: 'Analyze files',
            currentStep: viewModel.currentStep,
            activeStep: OptimizeStep.analyzing,
            doneSteps: const {
              OptimizeStep.awaitingConfirmation,
              OptimizeStep.cleaningUp,
              OptimizeStep.done,
              OptimizeStep.error,
            },
            doneSubtitle: _analysisSummary(viewModel),
            activeSubtitle: viewModel.fetchedFilesCount > 0
                ? 'Checked ${viewModel.analyzedCount} of ${viewModel.fetchedFilesCount}\u2026'
                : 'Checking files\u2026',
            doneColor: isAllDone ? green : null,
          ),
          _StepCard(
            stepNumber: 4,
            title: 'Clean up',
            currentStep: viewModel.currentStep,
            activeStep: OptimizeStep.cleaningUp,
            doneSteps: const {
              OptimizeStep.done,
              OptimizeStep.error,
            },
            skipped: isAllDone && !viewModel.hasFilesToClean,
            doneSubtitle: _cleanupSummary(viewModel),
            activeSubtitle: viewModel.totalToClean > 0
                ? 'Moving ${viewModel.deletedCount + viewModel.failedCount} of ${viewModel.totalToClean} to trash\u2026'
                : 'Moving files to trash\u2026',
            doneColor: isAllDone ? green : null,
          ),
          if (viewModel.currentStep == OptimizeStep.awaitingConfirmation) _buildConfirmation(context, viewModel),
          if (viewModel.currentStep == OptimizeStep.error) _buildError(context, viewModel),
        ],
      ),
    );
  }

  String _analysisSummary(CloudOptimizeViewModel vm) {
    if (!vm.hasFindings) return 'Nothing to clean up';
    final parts = <String>[];
    if (vm.detachedCandidates.isNotEmpty) {
      parts.add('${vm.detachedCandidates.length} detached (eligible for trash)');
    } else if (vm.detachedFiles.isNotEmpty) {
      parts.add('${vm.detachedFiles.length} detached (too recent)');
    }
    if (vm.staleDuplicates.isNotEmpty) {
      parts.add('${vm.staleDuplicates.length} stale duplicate${vm.staleDuplicates.length == 1 ? '' : 's'}');
    }
    return '${parts.join(', ')} found';
  }

  String _cleanupSummary(CloudOptimizeViewModel vm) {
    if (vm.deletedCount == 0 && vm.failedCount == 0) return 'No files moved to trash';
    final parts = <String>[];
    if (vm.deletedCount > 0) parts.add('${vm.deletedCount} moved to trash');
    if (vm.failedCount > 0) parts.add('${vm.failedCount} failed');
    return parts.join(', ');
  }

  Widget _buildConfirmation(BuildContext context, CloudOptimizeViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = TextTheme.of(context);
    final bytesToClean = viewModel.totalBytesToClean;

    final rows = <(String, String)>[
      if (viewModel.detachedCandidates.isNotEmpty)
        ('Detached files (eligible for trash)', '${viewModel.detachedCandidates.length}'),
      if (viewModel.detachedFiles.length > viewModel.detachedCandidates.length)
        (
          'Detached files (too recent, skipped)',
          '${viewModel.detachedFiles.length - viewModel.detachedCandidates.length}',
        ),
      if (viewModel.staleDuplicates.isNotEmpty) ('Safe stale duplicates', '${viewModel.staleDuplicates.length}'),
      if (bytesToClean > 0) ('Space to free', _formatBytes(bytesToClean)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final row in rows) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(row.$1, style: textTheme.bodySmall),
                      Text(row.$2, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (row != rows.last) const SizedBox(height: 4),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(SpIcons.info, size: 14, color: colorScheme.outline),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  viewModel.hasFilesToClean
                      ? 'Files will be moved to Google Drive trash.'
                      : 'No eligible files to clean up.',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: viewModel.hasFilesToClean ? () => viewModel.startCleanup() : () => Navigator.of(context).pop(),
              child: Text(viewModel.hasFilesToClean ? 'Move to trash' : 'Done'),
            ),
          ),
        ],
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

  Widget _buildError(BuildContext context, CloudOptimizeViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewModel.errorMessage ?? 'An unexpected error occurred.',
            style: TextTheme.of(context).bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => viewModel.retry(),
            icon: const Icon(SpIcons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.currentStep,
    required this.activeStep,
    required this.doneSteps,
    required this.doneSubtitle,
    required this.activeSubtitle,
    this.skipped = false,
    this.doneColor,
  });

  final int stepNumber;
  final String title;
  final OptimizeStep currentStep;
  final OptimizeStep activeStep;
  final Set<OptimizeStep> doneSteps;
  final String doneSubtitle;
  final String activeSubtitle;
  final bool skipped;
  final Color? doneColor;

  bool get _isActive => currentStep == activeStep;
  bool get _isDone => doneSteps.contains(currentStep) || skipped;
  bool get _isPending => !_isActive && !_isDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = TextTheme.of(context);

    final badgeColor = _isDone
        ? (doneColor ?? colorScheme.primary)
        : _isActive
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    final badgeTextColor = _isDone || _isActive ? colorScheme.onPrimary : colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadge(badgeColor, badgeTextColor, colorScheme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _isPending ? colorScheme.outline : null,
                  ),
                ),
                const SizedBox(height: 2),
                if (_isActive) ...[
                  LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 4),
                  Text(activeSubtitle, style: textTheme.bodySmall),
                ] else if (_isDone) ...[
                  Text(
                    skipped ? 'All clean - nothing to remove' : doneSubtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: doneColor?.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(Color badgeColor, Color textColor, ColorScheme colorScheme) {
    if (_isDone) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
        child: Icon(SpIcons.check, size: 14, color: textColor),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: _isPending ? Colors.transparent : badgeColor,
        shape: BoxShape.circle,
        border: _isPending ? Border.all(color: colorScheme.outlineVariant) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$stepNumber',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _isPending ? colorScheme.outline : textColor,
        ),
      ),
    );
  }
}
