part of 'video_compression_view.dart';

class _VideoCompressionContent extends StatelessWidget {
  const _VideoCompressionContent(this.viewModel);

  final VideoCompressionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    // Nothing here may pop: the route is removed by `VideoCompressionRoute.run`
    // when the work settles, so an Android back gesture must not race it.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                mainAxisSize: .min,
                children: [
                  _buildIcon(context),
                  const SizedBox(height: 24),
                  _buildTitle(context),
                  const SizedBox(height: 8),
                  _buildMessage(context),
                  const SizedBox(height: 24),
                  _buildProgressBar(context),
                  const SizedBox(height: 24),
                  _buildCancelButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return CircleAvatar(
      radius: 48,
      backgroundColor: ColorScheme.of(context).readOnly.surface3,
      child: Icon(
        SpIcons.videoCamera,
        size: 48,
        color: ColorScheme.of(context).primary,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      tr('page.video_compression.title'),
      textAlign: .center,
      style: TextTheme.of(context).titleMedium,
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        viewModel.message,
        textAlign: .center,
        style: TextTheme.of(context).bodyMedium?.copyWith(
          color: ColorScheme.of(context).onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        spacing: 8.0,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: viewModel.started ? viewModel.value : null,
              minHeight: 8.0,
            ),
          ),
          Text(
            viewModel.statusLabel,
            style: TextTheme.of(context).labelMedium?.copyWith(
              color: ColorScheme.of(context).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return TextButton(
      onPressed: viewModel.cancelled ? null : () => viewModel.cancel(),
      child: Text(tr('button.cancel')),
    );
  }
}
