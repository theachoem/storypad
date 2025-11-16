part of 'delete_backup_provider_view.dart';

class _DeleteBackupProviderContent extends StatelessWidget {
  const _DeleteBackupProviderContent(this.viewModel);

  final DeleteBackupProviderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(forceMaterialTransparency: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            "Are you sure to permanently delete?",
            style: TextTheme.of(context).titleMedium,
          ),
          const SizedBox(height: 8.0),
          Text(
            "Images, video, and other files will be deleted. You can't undo this action.",
            style: TextTheme.of(context).bodyMedium,
          ),
          const SizedBox(height: 8.0),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            icon: const Icon(SpIcons.deleteForever),
            label: const Text("Permanent Delete"),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
