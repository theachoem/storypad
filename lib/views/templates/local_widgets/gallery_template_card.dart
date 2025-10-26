part of 'gallery_tab.dart';

class _GalleryTemplateCard extends StatelessWidget {
  const _GalleryTemplateCard({
    required this.template,
    required this.onTap,
  });

  final GalleryTemplateObject template;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return SpTapEffect(
      onTap: onTap,
      effects: [
        SpTapEffectType.touchableOpacity,
        SpTapEffectType.scaleDown,
      ],
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SpFirestoreStorageDownloaderBuilder(
              filePath: template.iconUrlPath,
              builder: (context, file, failed) {
                if (failed) return const SizedBox(width: 36, height: 36);
                if (file == null) return const SpGradientLoading(height: 36, width: 26, shape: BoxShape.circle);

                return Image.file(
                  file,
                  width: 36,
                  height: 36,
                  semanticLabel: template.name,
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              template.name,
              style: TextTheme.of(context).titleMedium,
            ),
            Text(
              template.purpose,
              style: TextTheme.of(context).bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
