enum InAppUpdateStatus {
  downloading,
  updateAvailable,
  installAvailable;

  String get label {
    switch (this) {
      case downloading:
        return 'Updating...';
      case updateAvailable:
        return 'Update';
      case installAvailable:
        return 'Install';
    }
  }

  bool get loading => this == downloading;
}
