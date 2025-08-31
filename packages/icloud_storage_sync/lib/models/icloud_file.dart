class ICloudFile {
  /// File path relative to the iCloud container
  final String relativePath;

  /// Corresponding to NSMetadataItemFSSizeKey
  final int sizeInBytes;

  /// Corresponding to NSMetadataItemFSCreationDateKey
  final DateTime creationDate;

  /// Corresponding to NSMetadataItemFSContentChangeDateKey
  final DateTime contentChangeDate;

  /// Corresponding to NSMetadataUbiquitousItemIsDownloadingKey
  final bool isDownloading;

  /// Corresponding to NSMetadataUbiquitousItemDownloadingStatusKey
  final DownloadStatus downloadStatus;

  /// Corresponding to NSMetadataUbiquitousItemIsUploadingKey
  final bool isUploading;

  /// Corresponding to NSMetadataUbiquitousItemIsUploadedKey
  final bool isUploaded;

  /// Corresponding to NSMetadataUbiquitousItemHasUnresolvedConflictsKey
  final bool hasUnresolvedConflicts;

  /// Constructor to create the object from the map passed from platform code
  ICloudFile.fromMap(Map<dynamic, dynamic> map)
      : relativePath = map['relativePath'] as String,
        sizeInBytes = map['sizeInBytes'],
        creationDate = DateTime.fromMillisecondsSinceEpoch(
            ((map['creationDate'] as double) * 1000).round()),
        contentChangeDate = DateTime.fromMillisecondsSinceEpoch(
            ((map['contentChangeDate'] as double) * 1000).round()),
        isDownloading = map['isDownloading'],
        downloadStatus = _mapToDownloadStatusFromNSKeys(map['downloadStatus']),
        isUploading = map['isUploading'],
        isUploaded = map['isUploaded'],
        hasUnresolvedConflicts = map['hasUnresolvedConflicts'];

  /// Map native download status keys to DownloadStatus enum
  static DownloadStatus _mapToDownloadStatusFromNSKeys(String key) {
    switch (key) {
      case 'NSMetadataUbiquitousItemDownloadingStatusNotDownloaded':
        return DownloadStatus.notDownloaded;
      case 'NSMetadataUbiquitousItemDownloadingStatusDownloaded':
        return DownloadStatus.downloaded;
      case 'NSMetadataUbiquitousItemDownloadingStatusCurrent':
        return DownloadStatus.current;
      default:
        throw 'NSMetadataUbiquitousItemDownloadingStatusKey is not handled';
    }
  }
}

/// Download status of the File
enum DownloadStatus {
  /// Corresponding to NSMetadataUbiquitousItemDownloadingStatusNotDownloaded
  /// This item has not been downloaded yet.
  notDownloaded,

  /// Corresponding to NSMetadataUbiquitousItemDownloadingStatusDownloaded
  /// There is a local version of this item available.
  /// The most current version will get downloaded as soon as possible.
  downloaded,

  /// Corresponding to NSMetadataUbiquitousItemDownloadingStatusCurrent
  /// There is a local version of this item and it is the most up-to-date
  /// version known to this device.
  current,
}
