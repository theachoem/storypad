part of '../library_view.dart';

class _ImageStatus extends StatelessWidget {
  const _ImageStatus({
    required this.context,
    required this.asset,
    required this.provider,
  });

  final BuildContext context;
  final AssetDbModel asset;
  final BackupProvider provider;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (!asset.isGoogleDriveUploadedFor(provider.currentUser?.email)) {
      child = CircleAvatar(
        radius: 16.0,
        backgroundColor: ColorScheme.of(context).bootstrap.warning.color,
        foregroundColor: ColorScheme.of(context).bootstrap.warning.onColor,
        child: Icon(
          SpIcons.cloudOff,
          size: 20.0,
        ),
      );
    } else if (asset.isGoogleDriveUploadedFor(provider.currentUser?.email)) {
      child = Tooltip(
        message: asset.getGoogleDriveUrlForEmail(provider.currentUser!.email),
        child: CircleAvatar(
          radius: 16.0,
          backgroundColor: ColorScheme.of(context).bootstrap.success.color,
          foregroundColor: ColorScheme.of(context).bootstrap.success.onColor,
          child: const Icon(
            SpIcons.cloudDone,
            size: 20.0,
          ),
        ),
      );
    } else {
      child = CircleAvatar(
        radius: 16.0,
        backgroundColor: ColorScheme.of(context).bootstrap.info.color,
        foregroundColor: ColorScheme.of(context).bootstrap.info.onColor,
        child: const Icon(
          SpIcons.warning,
          size: 20.0,
        ),
      );
    }

    return Positioned(
      top: 8.0,
      right: 8.0,
      child: child,
    );
  }
}
