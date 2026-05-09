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
    if (!asset.isGoogleDriveUploadedFor(provider.currentGoogleUser?.email)) {
      return SpAssetStatusBadge(
        top: 8.0,
        right: 8.0,
        radius: 16.0,
        iconSize: 20.0,
        backgroundColor: ColorScheme.of(context).bootstrap.warning.color,
        foregroundColor: ColorScheme.of(context).bootstrap.warning.onColor,
        icon: SpIcons.cloudOff,
      );
    } else if (asset.isGoogleDriveUploadedFor(provider.currentGoogleUser?.email)) {
      return SpAssetStatusBadge(
        top: 8.0,
        right: 8.0,
        radius: 16.0,
        iconSize: 20.0,
        backgroundColor: ColorScheme.of(context).bootstrap.success.color,
        foregroundColor: ColorScheme.of(context).bootstrap.success.onColor,
        icon: SpIcons.cloudDone,
        tooltipMessage: asset.getGoogleDriveUrlForEmail(provider.currentGoogleUser!.email),
      );
    } else {
      return SpAssetStatusBadge(
        top: 8.0,
        right: 8.0,
        radius: 16.0,
        iconSize: 20.0,
        backgroundColor: ColorScheme.of(context).bootstrap.info.color,
        foregroundColor: ColorScheme.of(context).bootstrap.info.onColor,
        icon: SpIcons.warning,
      );
    }
  }
}
