import Cocoa
import CloudKit
import FlutterMacOS

/// Native side of `ICloudCloudService` (Dart) — file storage in the app's
/// private iCloud ubiquity container, under a non-Documents `Data/` root so
/// it never surfaces in the Files app (unlike a `NSUbiquitousContainers`
/// documents-visible container). All paths passed across the channel are
/// relative to that `Data/` root.
///
/// Platform port of `ios/Runner/services/ICloudBackupService.swift` — kept as
/// a separate file rather than a shared/symlinked source (no precedent for
/// sharing native source between the `ios/` and `macos/` Xcode projects
/// exists in this repo, and the two files differ only in `openAppSettings`
/// below and this import line). Keep the two in sync when changing anything
/// else — CloudKit/FileManager/NSFileCoordinator logic here is intentionally
/// identical to the iOS version.
///
/// There is no in-app sign-in: availability is derived live from whether
/// the ubiquity container resolves at all (fast, local, no network — see
/// `isAvailable`), true only when the device is signed into iCloud AND the
/// user has iCloud Drive enabled for this app in System Settings — see
/// `openAppSettings`, the only way to change that from inside the app.
/// Actual account *identity* (for `AssetDbModel.cloudDestinations`
/// bookkeeping and RevenueCat's `globalId` alias) comes from CloudKit's
/// `fetchUserRecordID` instead (see `fetchAccountId`) — genuinely stable
/// across every device signed into the same account, unlike
/// `FileManager.ubiquityIdentityToken`, which Apple only documents as
/// stable across launches on the *same* device (and which `isAvailable`
/// deliberately avoids for a second reason — see its own doc comment).
///
/// `ubiquityIdentityToken` does get one narrow, supplementary use —
/// `fetchIdentityTokenFingerprint` — as a cheap, local, no-network "has the
/// signed-in iCloud account changed" signal for the Dart layer to fall back
/// on specifically when `fetchAccountId` fails transiently (so it can't just
/// ask CloudKit "is this still the same account"). It is never treated as
/// identity itself, only compared for equality against a previously-recorded
/// value.
class ICloudBackupService {
  private static let dataFolderName = "Data"

  /// Apple documents `url(forUbiquityContainerIdentifier:)` as unsafe to call
  /// on the main thread (it can do real first-call container setup work) —
  /// every accessor below resolves this from inside a background dispatch,
  /// never synchronously in a method-channel callback.
  private static var containerURL: URL? {
    // Passing nil resolves to the first container identifier listed in the
    // entitlements — avoids hardcoding a per-flavor container ID here.
    FileManager.default.url(forUbiquityContainerIdentifier: nil)
  }

  private static var dataRootURL: URL? {
    containerURL?.appendingPathComponent(dataFolderName, isDirectory: true)
  }

  // MARK: - Dispatch

  /// Routes a `default_platform_channel` call to this service if it's one of
  /// ours, returning whether it was handled — see `MainFlutterWindow.swift`,
  /// which chains every service's `handle` rather than switching on method
  /// names itself. Owns its own argument extraction so the caller doesn't
  /// have to.
  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) -> Bool {
    let arguments = call.arguments as? [String: Any]

    switch call.method {
    case "ICloudBackupService.isAvailable":
      isAvailable(result: result)
    case "ICloudBackupService.fetchAccountId":
      fetchAccountId(result: result)
    case "ICloudBackupService.fetchIdentityTokenFingerprint":
      fetchIdentityTokenFingerprint(result: result)
    case "ICloudBackupService.openAppSettings":
      openAppSettings(result: result)
    case "ICloudBackupService.statFile":
      guard let relativePath = arguments?["relativePath"] as? String else {
        invalidArgs(result, "relativePath is required")
        return true
      }
      statFile(relativePath: relativePath, result: result)
    case "ICloudBackupService.listFiles":
      let relativeFolderPath = arguments?["relativeFolderPath"] as? String ?? ""
      listFiles(relativeFolderPath: relativeFolderPath, result: result)
    case "ICloudBackupService.uploadFile":
      guard let localPath = arguments?["localPath"] as? String,
        let relativePath = arguments?["relativePath"] as? String
      else {
        invalidArgs(result, "localPath and relativePath are required")
        return true
      }
      uploadFile(localPath: localPath, relativePath: relativePath, result: result)
    case "ICloudBackupService.downloadFile":
      guard let relativePath = arguments?["relativePath"] as? String else {
        invalidArgs(result, "relativePath is required")
        return true
      }
      downloadFile(relativePath: relativePath, result: result)
    case "ICloudBackupService.deleteFile":
      guard let relativePath = arguments?["relativePath"] as? String else {
        invalidArgs(result, "relativePath is required")
        return true
      }
      deleteFile(relativePath: relativePath, result: result)
    case "ICloudBackupService.moveFile":
      guard let fromRelativePath = arguments?["fromRelativePath"] as? String,
        let toRelativePath = arguments?["toRelativePath"] as? String
      else {
        invalidArgs(result, "fromRelativePath and toRelativePath are required")
        return true
      }
      moveFile(fromRelativePath: fromRelativePath, toRelativePath: toRelativePath, result: result)
    default:
      // Not one of ours — the method name didn't match any case above, so
      // nothing has called `result` yet and it's safe for the caller to try
      // the next service (or report FlutterMethodNotImplemented).
      return false
    }

    return true
  }

  /// A bad payload for one of our own method names is still "handled" (the
  /// call must not fall through to another service's `handle` or to
  /// `FlutterMethodNotImplemented` — `result` has already been invoked here).
  /// Every call site returns `true` right after this for that reason.
  private static func invalidArgs(_ result: @escaping FlutterResult, _ message: String) {
    result(FlutterError(code: "INVALID_ARGS", message: message, details: nil))
  }

  // MARK: - Availability

  /// Deliberately checks container resolution directly rather than
  /// `FileManager.ubiquityIdentityToken` — Apple's documentation of that
  /// property is ambiguous about whether it reflects only device-wide
  /// iCloud sign-in or also this app's specific "iCloud Drive" access, and
  /// getting that wrong either way is exactly the kind of thing that goes
  /// undetected until a real sync silently fails. Resolving the container
  /// URL is the actual, unambiguous answer to "can this app use its
  /// container right now" — true regardless of *why* it might be
  /// unavailable (device not signed in, this app's access specifically
  /// revoked, or anything else).
  ///
  /// Dispatched off the calling thread: `url(forUbiquityContainerIdentifier:)`
  /// can do real first-call setup work and Apple documents it as unsafe to
  /// call on the main thread — this is invoked from every resume/connection
  /// check, so staying on whatever thread the method channel handed us
  /// (typically main) risked a UI hitch on every one of those.
  static func isAvailable(result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      let available = dataRootURL != nil
      DispatchQueue.main.async {
        result(available)
      }
    }
  }

  /// `CKRecord.ID.recordName` for the default CloudKit container's current
  /// user record — genuinely stable across every device signed into the
  /// same iCloud account (Apple documents this, unlike
  /// `ubiquityIdentityToken`), and changes when the signed-in account
  /// changes. Requires network (a real CloudKit round-trip), so callers
  /// should treat `NETWORK`-coded failures as transient rather than "not
  /// signed in" — see the error mapping below.
  static func fetchAccountId(result: @escaping FlutterResult) {
    // Passing nil resolves to the default container derived from the app's
    // entitlements, same convenience as `containerURL` above — no per-flavor
    // container ID hardcoded here either.
    CKContainer.default().fetchUserRecordID { recordID, error in
      if let error = error {
        DispatchQueue.main.async {
          result(cloudKitError(error))
        }
        return
      }

      DispatchQueue.main.async {
        result(recordID?.recordName)
      }
    }
  }

  private static func cloudKitError(_ error: Error) -> FlutterError {
    guard let ckError = error as? CKError else {
      return FlutterError(code: "FAILED", message: error.localizedDescription, details: nil)
    }

    switch ckError.code {
    case .notAuthenticated:
      return FlutterError(code: "NO_CONTAINER", message: ckError.localizedDescription, details: nil)
    case .networkUnavailable, .networkFailure, .requestRateLimited, .serviceUnavailable, .zoneBusy:
      return FlutterError(code: "NETWORK", message: ckError.localizedDescription, details: nil)
    default:
      return FlutterError(code: "FAILED", message: ckError.localizedDescription, details: nil)
    }
  }

  /// A cheap, local, no-network stand-in for "is this still the same signed-in
  /// iCloud account as before" — used only when `fetchAccountId` can't answer
  /// that authoritatively itself (a transient CloudKit failure). Never
  /// exposed/used as identity: just an opaque string the Dart layer persists
  /// alongside the confirmed account and compares for equality later. Archived
  /// with `requiringSecureCoding: false` deliberately — the token's underlying
  /// type doesn't conform to `NSSecureCoding`, so `true` here throws on every
  /// call (this bit us once already, back when this token was tried as the
  /// primary identity source before CloudKit replaced it).
  static func fetchIdentityTokenFingerprint(result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      let fingerprint = currentIdentityTokenFingerprint()
      DispatchQueue.main.async {
        result(fingerprint)
      }
    }
  }

  private static func currentIdentityTokenFingerprint() -> String? {
    guard let token = FileManager.default.ubiquityIdentityToken else { return nil }
    guard let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false) else {
      return nil
    }
    return data.base64EncodedString()
  }

  /// macOS has no per-app Settings page the way iOS does (no
  /// `UIApplication.openSettingsURLString` analogue) — the closest genuinely
  /// public, documented equivalent is launching the System Settings app
  /// itself via its bundle identifier, never an undocumented
  /// `x-apple.systempreferences:` pane URL (same "no private deep link"
  /// principle already applied on iOS). The user still has to navigate to
  /// iCloud → See All → this app themselves — the demo-image sheet on the
  /// Dart side carries that guidance, same as iOS.
  static func openAppSettings(result: @escaping FlutterResult) {
    guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.systempreferences") else {
      result(FlutterError(code: "FAILED", message: "Could not locate System Settings", details: nil))
      return
    }

    DispatchQueue.main.async {
      NSWorkspace.shared.open(url)
      result(true)
    }
  }

  // MARK: - File operations

  /// Resolves the container and reads file metadata entirely off the calling
  /// thread — both `dataRootURL` (which can do first-call container setup
  /// work) and `fileExists`/`attributesOfItem` (real filesystem I/O) are
  /// unsafe to run synchronously on whatever thread the method channel
  /// handed us (typically main).
  static func statFile(relativePath: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      guard let dataRoot = dataRootURL else {
        DispatchQueue.main.async {
          result(containerUnavailableError())
        }
        return
      }

      let url = dataRoot.appendingPathComponent(relativePath)
      guard FileManager.default.fileExists(atPath: url.path) else {
        DispatchQueue.main.async {
          result(nil)
        }
        return
      }

      let metadata = metadataDictionary(for: url, dataRoot: dataRoot)
      DispatchQueue.main.async {
        result(metadata)
      }
    }
  }

  /// Plain (coordinated) directory listing rather than `NSMetadataQuery` —
  /// that API's search scopes (`NSMetadataQueryUbiquitousDocumentsScope`
  /// etc.) only index the ubiquity container's `Documents/` subfolder, which
  /// we deliberately don't use (see the class doc: everything lives under
  /// `Data/` instead, to stay out of the Files app). A scoped metadata query
  /// against `Data/` would always come back empty regardless of what's
  /// actually there. `contentsOfDirectory` has no such restriction — it
  /// reflects files uploaded by any device on the account, not just ones
  /// already downloaded locally, since iCloud syncs the file list/metadata
  /// ahead of content.
  static func listFiles(relativeFolderPath: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      guard let dataRoot = dataRootURL else {
        DispatchQueue.main.async {
          result(containerUnavailableError())
        }
        return
      }

      let folderURL = relativeFolderPath.isEmpty
        ? dataRoot
        : dataRoot.appendingPathComponent(relativeFolderPath, isDirectory: true)

      var entries: [URL] = []
      var coordinatorError: NSError?
      var readError: Error?
      let coordinator = NSFileCoordinator()

      coordinator.coordinate(readingItemAt: folderURL, options: [], error: &coordinatorError) { url in
        do {
          entries = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
          )
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
          // Genuinely nothing there yet (e.g. no uploads yet) — distinct
          // from every other failure below, which must not be silently
          // reported as "zero files": a transient network/permission error
          // here previously looked identical to an empty folder, which sync
          // and the cloud-optimize orphan detector could misread as "there's
          // nothing to preserve".
          entries = []
        } catch {
          readError = error
        }
      }

      let files = entries.compactMap { itemURL -> [String: Any?]? in
        let isDirectory = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
        return isDirectory ? nil : metadataDictionary(for: itemURL, dataRoot: dataRoot)
      }

      DispatchQueue.main.async {
        if let coordinatorError = coordinatorError {
          result(coordinationError(coordinatorError))
        } else if let readError = readError {
          result(fileOperationError(readError))
        } else {
          result(files)
        }
      }
    }
  }

  static func uploadFile(localPath: String, relativePath: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      guard let dataRoot = dataRootURL else {
        DispatchQueue.main.async {
          result(containerUnavailableError())
        }
        return
      }

      let destURL = dataRoot.appendingPathComponent(relativePath)
      let sourceURL = URL(fileURLWithPath: localPath)

      var coordinatorError: NSError?
      var operationError: Error?
      let coordinator = NSFileCoordinator()

      coordinator.coordinate(writingItemAt: destURL, options: .forReplacing, error: &coordinatorError) { url in
        do {
          try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
          )
          try replaceItem(at: url, placingContentFrom: sourceURL) { source, temp in
            try FileManager.default.copyItem(at: source, to: temp)
          }
        } catch {
          operationError = error
        }
      }

      DispatchQueue.main.async {
        if let coordinatorError = coordinatorError {
          result(coordinationError(coordinatorError))
        } else if let operationError = operationError {
          result(fileOperationError(operationError))
        } else {
          result(metadataDictionary(for: destURL, dataRoot: dataRoot))
        }
      }
    }
  }

  static func downloadFile(relativePath: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      guard let dataRoot = dataRootURL else {
        DispatchQueue.main.async {
          result(containerUnavailableError())
        }
        return
      }

      let fileURL = dataRoot.appendingPathComponent(relativePath)
      guard FileManager.default.fileExists(atPath: fileURL.path) else {
        DispatchQueue.main.async {
          result(nil)
        }
        return
      }

      do {
        try FileManager.default.startDownloadingUbiquitousItem(at: fileURL)
      } catch {
        let downloadStartError = fileOperationError(error)
        DispatchQueue.main.async {
          result(downloadStartError)
        }
        return
      }

      waitForDownload(at: fileURL) { downloadError in
        if let downloadError = downloadError {
          result(downloadError)
          return
        }

        // waitForDownload's completion runs on the main queue (see its own doc
        // comment) — reading the whole file synchronously here would block the
        // UI for any large backup/asset, so hop off before doing it.
        DispatchQueue.global(qos: .userInitiated).async {
          var coordinatorError: NSError?
          var readData: Data?
          var readError: Error?
          let coordinator = NSFileCoordinator()

          coordinator.coordinate(readingItemAt: fileURL, options: [], error: &coordinatorError) { url in
            do {
              readData = try Data(contentsOf: url)
            } catch {
              readError = error
            }
          }

          DispatchQueue.main.async {
            if let coordinatorError = coordinatorError {
              result(coordinationError(coordinatorError))
            } else if let readError = readError {
              result(fileOperationError(readError))
            } else if let readData = readData {
              result(FlutterStandardTypedData(bytes: readData))
            } else {
              result(nil)
            }
          }
        }
      }
    }
  }

  /// Coordinates `.forDeleting` on the item's own URL — the pattern Apple
  /// documents for removing a ubiquity item. The previous version coordinated
  /// a `.forMerging` write on the *parent folder* instead (meant for adding
  /// new content that merges into a folder, not for removing one child from
  /// it) and never even read back the coordinator's own remapped URL. With
  /// the wrong coordination scope, the local `removeItem` still succeeds
  /// (so an immediate re-list even looked correct), but iCloud's sync daemon
  /// never received a properly-scoped "this item was deleted" signal — so it
  /// would "heal" the improperly-coordinated local delete by re-downloading
  /// the file from the still-intact cloud copy, which is exactly the bug
  /// reported: delete appears to succeed, then the file reappears.
  static func deleteFile(relativePath: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      guard let dataRoot = dataRootURL else {
        DispatchQueue.main.async {
          result(containerUnavailableError())
        }
        return
      }

      let url = dataRoot.appendingPathComponent(relativePath)

      var coordinatorError: NSError?
      var operationError: Error?
      let coordinator = NSFileCoordinator()

      coordinator.coordinate(writingItemAt: url, options: .forDeleting, error: &coordinatorError) { coordinatedURL in
        do {
          if FileManager.default.fileExists(atPath: coordinatedURL.path) {
            try FileManager.default.removeItem(at: coordinatedURL)
          }
        } catch {
          operationError = error
        }
      }

      DispatchQueue.main.async {
        if let coordinatorError = coordinatorError {
          result(coordinationError(coordinatorError))
        } else if let operationError = operationError {
          result(fileOperationError(operationError))
        } else {
          result(true)
        }
      }
    }
  }

  /// Backs both `trashFile` and `restoreFileFromTrash` on the Dart side —
  /// which direction it moves is just which relative path is "from" and
  /// which is "to". Coordinates both the source (`.forMoving`) and
  /// destination (`.forReplacing`) URLs together in one call — Apple's
  /// documented pattern for a coordinated move — for the same reason
  /// `deleteFile` coordinates `.forDeleting` on the specific item rather
  /// than `.forMerging` on the parent folder: the wrong coordination scope
  /// lets the local move succeed while leaving iCloud's sync daemon without
  /// a properly-scoped signal, so it can silently restore the source file
  /// from the cloud after the fact.
  static func moveFile(fromRelativePath: String, toRelativePath: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      guard let dataRoot = dataRootURL else {
        DispatchQueue.main.async {
          result(containerUnavailableError())
        }
        return
      }

      let sourceURL = dataRoot.appendingPathComponent(fromRelativePath)
      let destURL = dataRoot.appendingPathComponent(toRelativePath)

      var coordinatorError: NSError?
      var operationError: Error?
      let coordinator = NSFileCoordinator()

      coordinator.coordinate(
        writingItemAt: sourceURL,
        options: .forMoving,
        writingItemAt: destURL,
        options: .forReplacing,
        error: &coordinatorError
      ) { coordinatedSource, coordinatedDest in
        do {
          try FileManager.default.createDirectory(
            at: coordinatedDest.deletingLastPathComponent(),
            withIntermediateDirectories: true
          )
          try replaceItem(at: coordinatedDest, placingContentFrom: coordinatedSource) { source, temp in
            try FileManager.default.moveItem(at: source, to: temp)
          }
        } catch {
          operationError = error
        }
      }

      DispatchQueue.main.async {
        if let coordinatorError = coordinatorError {
          result(coordinationError(coordinatorError))
        } else if let operationError = operationError {
          result(fileOperationError(operationError))
        } else {
          result(true)
        }
      }
    }
  }

  // MARK: - Helpers

  /// Places new content at `destURL` without ever deleting whatever's
  /// already there before the replacement is confirmed on disk. The
  /// previous pattern (`if exists { removeItem }` then `copyItem`/`moveItem`)
  /// had a real data-loss window: if the second step threw (disk pressure, a
  /// source race, an iCloud error), the destination was left empty/gone —
  /// and that deletion could itself sync to iCloud, destroying the only
  /// remaining copy. `operation` writes the new content to a temporary
  /// sibling first; only once that succeeds does this touch `destURL`, via
  /// an atomic swap when something was already there.
  ///
  /// If the final swap itself fails, the temp file is deliberately left in
  /// place rather than deleted — for `moveFile` in particular, `operation`
  /// has already moved the only copy of the file out of its original
  /// location by this point, so the temp copy is the sole surviving copy;
  /// an orphaned `.tmp-*` file is a far safer failure mode than actively
  /// destroying it.
  private static func replaceItem(
    at destURL: URL,
    placingContentFrom sourceURL: URL,
    using operation: (_ source: URL, _ temp: URL) throws -> Void
  ) throws {
    let tempURL = destURL.deletingLastPathComponent()
      .appendingPathComponent(".tmp-\(UUID().uuidString)-\(destURL.lastPathComponent)")

    try operation(sourceURL, tempURL)

    if FileManager.default.fileExists(atPath: destURL.path) {
      _ = try FileManager.default.replaceItemAt(destURL, withItemAt: tempURL)
    } else {
      try FileManager.default.moveItem(at: tempURL, to: destURL)
    }
  }

  /// Polls `url`'s `ubiquitousItemDownloadingStatus` directly until it's
  /// `.current`, or [timeout] elapses. A freshly-`startDownloadingUbiquitousItem`
  /// file isn't guaranteed to have its bytes on disk yet — reading too early
  /// would return stale/partial content.
  ///
  /// Deliberately plain `resourceValues` polling, not `NSMetadataQuery` (as
  /// an earlier version of this did) — that API's search scopes only index
  /// the container's `Documents/` subfolder, which this file under `Data/`
  /// isn't in, so a scoped query would never observe it and this would
  /// always hang until timeout. `resourceValues` reads the specific URL
  /// directly and has no such restriction.
  private static func waitForDownload(
    at url: URL,
    timeout: TimeInterval = 60,
    pollInterval: TimeInterval = 0.5,
    completion: @escaping (FlutterError?) -> Void
  ) {
    let deadline = Date().addingTimeInterval(timeout)

    func poll() {
      let status = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
        .ubiquitousItemDownloadingStatus

      if status == .current {
        completion(nil)
        return
      }

      if Date() >= deadline {
        completion(FlutterError(code: "NETWORK", message: "Timed out waiting for iCloud download", details: nil))
        return
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + pollInterval) {
        poll()
      }
    }

    DispatchQueue.main.async {
      poll()
    }
  }

  private static func metadataDictionary(for url: URL, dataRoot: URL) -> [String: Any?] {
    let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
    let relativePath = url.path.hasPrefix(dataRoot.path)
      ? String(url.path.dropFirst(dataRoot.path.count + 1))
      : url.lastPathComponent

    return [
      "name": url.lastPathComponent,
      "path": relativePath,
      "sizeInBytes": attributes?[.size] as? Int,
      "createdAt": (attributes?[.creationDate] as? Date)?.timeIntervalSince1970,
      "modifiedAt": (attributes?[.modificationDate] as? Date)?.timeIntervalSince1970,
    ]
  }

  private static func containerUnavailableError() -> FlutterError {
    FlutterError(code: "NO_CONTAINER", message: "iCloud container is not available", details: nil)
  }

  private static func fileOperationError(_ error: Error) -> FlutterError {
    let nsError = error as NSError

    if nsError.domain == NSCocoaErrorDomain
      && (nsError.code == NSFileReadNoSuchFileError || nsError.code == NSFileNoSuchFileError)
    {
      return FlutterError(code: "NOT_FOUND", message: error.localizedDescription, details: nil)
    }

    if nsError.domain == NSURLErrorDomain || nsError.domain == NSCocoaErrorDomain
      && nsError.code == NSUbiquitousFileUnavailableError
    {
      return FlutterError(code: "NETWORK", message: error.localizedDescription, details: nil)
    }

    return FlutterError(code: "FAILED", message: error.localizedDescription, details: nil)
  }

  private static func coordinationError(_ error: NSError) -> FlutterError {
    FlutterError(code: "COORDINATION_FAILED", message: error.localizedDescription, details: nil)
  }
}
