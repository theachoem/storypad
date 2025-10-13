# Backup System

Comprehensive backup/sync implementation with Google Drive, featuring robust exception handling and retry logic.

## Architecture

**Exception Flow:**

```
Google Drive Client → Service → Repository → Provider
     (Throws)      → (Wraps) → (Result)  → (UI State)
```

## Components

### Exception Types (`lib/core/exceptions/backup_exceptions.dart`)

**Base:** `BackupException` - message, context, retry info

**Types:**

- `NetworkException` - Network issues (retryable)
- `AuthException` - Auth failures (tokenExpired, tokenRevoked, insufficientScopes, signInRequired, signInFailed)
- `QuotaException` - Drive quota/rate limits
- `FileOperationException` - File ops (retryable)
- `ServiceException` - Business logic errors
- `ConfigurationException` - Setup errors

### Result Types (`lib/core/types/backup_result.dart`)

**BackupResult<T>** (sealed):

- `BackupSuccess<T>` - Success
- `BackupFailure<T>` - Complete failure
- `BackupPartialSuccess<T>` - Mixed results

**BackupError:** Type classification, user messages, retry flags, metadata

### Retry Policy (`lib/core/utils/retry_policy.dart`)

- Configurable attempts, delays, exponential backoff
- Predefined: `RetryPolicy.network`, `RetryPolicy.quota`, `RetryPolicy.none`
- `RetryExecutor` - Auto retry with timeout

### Google Drive Client (`lib/core/services/google_drive_client.dart`)

- Token expiration/revocation detection
- HTTP status → exception mapping
- Auto retry for transient failures

### Services

- `BackupImagesUploaderService` - Image upload with retry
- `BackupUploaderService` - File upload with error handling
- `BackupLatestCheckerService` - Download with validation

### Repository (`lib/core/repositories/backup_repository.dart`)

- Returns `BackupResult<T>` (no throws)
- Auto sign-out on auth errors
- Connection status mapping

### Provider (`lib/providers/backup_provider.dart`)

- Handles `BackupResult` types
- User-friendly error messages
- Auto sign-out on token revocation

## Error Scenarios

| Scenario         | Detection                         | Handling                | UI Message                                   |
| ---------------- | --------------------------------- | ----------------------- | -------------------------------------------- |
| Token Expiration | 401 responses                     | Auto reauthentication   | "Session expired. Please sign in again."     |
| Token Revocation | 403 responses                     | Auto sign-out           | "Access revoked. Please sign in again."      |
| Network Issues   | SocketException, TimeoutException | Auto retry with backoff | "Network error. Check connection and retry." |
| Quota Exceeded   | Drive API errors                  | No retry, notify user   | "Drive storage full. Free up space."         |
| Rate Limiting    | 429 responses                     | Retry with delays       | "Too many requests. Wait and retry."         |

## Usage Pattern

```dart
// In ViewModel/Provider
final result = await backupRepository.upload();

result.when(
  success: (data) => handleSuccess(data),
  failure: (error) => showError(error.message),
  partialSuccess: (data, errors) => handlePartial(data, errors),
);
```

## Test Files

- `test/core/exceptions/backup_exceptions_test.dart`
- `test/core/types/backup_result_test.dart`
- `test/core/utils/retry_policy_test.dart`
- `test/core/services/google_drive_client_test.dart`

## Key Features

- **Type-safe error handling** - No throws, use `BackupResult<T>`
- **Auto retry** - Exponential backoff with jitter
- **Auth handling** - Token refresh, auto sign-out on revocation
- **User-friendly** - Clear error messages, offline support
