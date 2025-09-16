import 'package:easy_localization/easy_localization.dart';

enum InAppUpdateStatus {
  downloading,
  updateAvailable,
  installAvailable;

  String get label {
    switch (this) {
      case downloading:
        return tr('general.updating');
      case updateAvailable:
        return tr('general.update');
      case installAvailable:
        return tr('general.restart');
    }
  }

  bool get loading => this == downloading;
}
