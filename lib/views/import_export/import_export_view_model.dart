import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'import_export_view.dart';

class ImportExportViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ImportExportRoute params;

  ImportExportViewModel({
    required this.params,
  });
}
