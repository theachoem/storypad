// ignore_for_file: depend_on_referenced_packages

// These package already used by other package we used. We don't need to put them in our pubspec until necessary.
export 'package:path/path.dart' show basename, extension, join;
export 'package:path_provider/path_provider.dart'
    show getExternalStorageDirectory, getApplicationSupportDirectory, getApplicationDocumentsDirectory;
