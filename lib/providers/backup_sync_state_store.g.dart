// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_sync_state_store.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServiceSyncStatusCWProxy {
  ServiceSyncStatus activity(SyncActivity activity);

  ServiceSyncStatus currentStep(SyncStep? currentStep);

  ServiceSyncStatus message(String? message);

  ServiceSyncStatus connectionStatus(BackupConnectionStatus? connectionStatus);

  ServiceSyncStatus lastSyncedAt(DateTime? lastSyncedAt);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ServiceSyncStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServiceSyncStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  ServiceSyncStatus call({
    SyncActivity activity,
    SyncStep? currentStep,
    String? message,
    BackupConnectionStatus? connectionStatus,
    DateTime? lastSyncedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfServiceSyncStatus.copyWith(...)` or call `instanceOfServiceSyncStatus.copyWith.fieldName(value)` for a single field.
class _$ServiceSyncStatusCWProxyImpl implements _$ServiceSyncStatusCWProxy {
  const _$ServiceSyncStatusCWProxyImpl(this._value);

  final ServiceSyncStatus _value;

  @override
  ServiceSyncStatus activity(SyncActivity activity) => call(activity: activity);

  @override
  ServiceSyncStatus currentStep(SyncStep? currentStep) =>
      call(currentStep: currentStep);

  @override
  ServiceSyncStatus message(String? message) => call(message: message);

  @override
  ServiceSyncStatus connectionStatus(
    BackupConnectionStatus? connectionStatus,
  ) => call(connectionStatus: connectionStatus);

  @override
  ServiceSyncStatus lastSyncedAt(DateTime? lastSyncedAt) =>
      call(lastSyncedAt: lastSyncedAt);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ServiceSyncStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServiceSyncStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  ServiceSyncStatus call({
    Object? activity = const $CopyWithPlaceholder(),
    Object? currentStep = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? connectionStatus = const $CopyWithPlaceholder(),
    Object? lastSyncedAt = const $CopyWithPlaceholder(),
  }) {
    return ServiceSyncStatus(
      activity: activity == const $CopyWithPlaceholder() || activity == null
          ? _value.activity
          // ignore: cast_nullable_to_non_nullable
          : activity as SyncActivity,
      currentStep: currentStep == const $CopyWithPlaceholder()
          ? _value.currentStep
          // ignore: cast_nullable_to_non_nullable
          : currentStep as SyncStep?,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String?,
      connectionStatus: connectionStatus == const $CopyWithPlaceholder()
          ? _value.connectionStatus
          // ignore: cast_nullable_to_non_nullable
          : connectionStatus as BackupConnectionStatus?,
      lastSyncedAt: lastSyncedAt == const $CopyWithPlaceholder()
          ? _value.lastSyncedAt
          // ignore: cast_nullable_to_non_nullable
          : lastSyncedAt as DateTime?,
    );
  }
}

extension $ServiceSyncStatusCopyWith on ServiceSyncStatus {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfServiceSyncStatus.copyWith(...)` or `instanceOfServiceSyncStatus.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServiceSyncStatusCWProxy get copyWith =>
      _$ServiceSyncStatusCWProxyImpl(this);
}
