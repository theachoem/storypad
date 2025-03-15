part of '../backups_view.dart';

class _BackupTileMonogram extends StatelessWidget {
  const _BackupTileMonogram({
    required this.context,
    required this.fileInfo,
    required this.previousFileInfo,
  });

  final BuildContext context;
  final BackupFileObject? fileInfo;
  final BackupFileObject? previousFileInfo;

  @override
  Widget build(BuildContext context) {
    double monogramSize = 32;

    bool showMonogram = true;
    if (fileInfo == null) {
      showMonogram = false;
    } else if (previousFileInfo != null && fileInfo != null) {
      showMonogram = !previousFileInfo!.sameDayAs(fileInfo!);
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

    DateTime date = fileInfo!.createdAt;
    return Column(
      spacing: 4.0,
      children: [
        Container(
          width: monogramSize,
          color: ColorScheme.of(context).surface.withValues(),
          child: Text(
            DateFormatHelper.E(date, context.locale),
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
