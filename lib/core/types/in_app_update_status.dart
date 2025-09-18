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
        return tr('button.update');
      case installAvailable:
        return tr('button.restart');
    }
  }

  bool get loading => this == downloading;
}
