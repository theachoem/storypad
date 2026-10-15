/// Re-exports the exact `super_editor` version this package is built on, for apps that need its types (e.g. the
/// controller's `editor`/`document`/`composer` escape hatches, or custom stylesheet rules) without declaring their own
/// dependency on it -- which could otherwise resolve to a different, incompatible version.
library;

export 'package:super_editor/super_editor.dart';
