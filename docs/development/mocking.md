# Mocking

**Mocking with Mockito for unit tests.**

## Generating Mocks

### 1. Add annotation

```dart
import 'package:mockito/annotations.dart';

@GenerateMocks([StoryRepository, GoogleDriveClient])
void main() {
  // Tests here
}
```

### 2. Generate mocks

```bash
flutter pub run build_runner build
```

### 3. Use mocks

```dart
import 'my_test.mocks.dart';

final mockRepository = MockStoryRepository();
```

## Common Mock Patterns

### Return value

```dart
when(mock.method()).thenReturn(value);
```

### Return future

```dart
when(mock.method()).thenAnswer((_) async => value);
```

### Throw exception

```dart
when(mock.method()).thenThrow(Exception('Error'));
```

### Verify call

```dart
verify(mock.method()).called(1);
verifyNever(mock.method());
```

### Verify with any argument

```dart
verify(mock.method(any)).called(1);
```

### Capture arguments

```dart
final captured = verify(mock.method(captureAny)).captured;
expect(captured.first, expectedValue);
```

## Complete Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'backup_service_test.mocks.dart';

@GenerateMocks([GoogleDriveClient, StoryRepository])
void main() {
  group('BackupService', () {
    late BackupService service;
    late MockGoogleDriveClient mockClient;
    late MockStoryRepository mockRepository;

    setUp(() {
      mockClient = MockGoogleDriveClient();
      mockRepository = MockStoryRepository();
      service = BackupService(
        client: mockClient,
        repository: mockRepository,
      );
    });

    test('should upload backup successfully', () async {
      // Arrange
      final stories = [StoryDbModel(title: 'Test')];
      when(mockRepository.getAll()).thenReturn(stories);
      when(mockClient.upload(any)).thenAnswer((_) async => 'file_id');

      // Act
      final result = await service.uploadBackup();

      // Assert
      expect(result.isSuccess, true);
      verify(mockRepository.getAll()).called(1);
      verify(mockClient.upload(any)).called(1);
    });

    test('should handle upload error', () async {
      // Arrange
      when(mockRepository.getAll()).thenReturn([]);
      when(mockClient.upload(any)).thenThrow(Exception('Upload failed'));

      // Act
      final result = await service.uploadBackup();

      // Assert
      expect(result.isFailure, true);
      verify(mockClient.upload(any)).called(1);
    });
  });
}
```

## Mocking Tips

### Mock only external dependencies

```dart
// ✅ Mock external dependencies
final mockRepository = MockStoryRepository();
final mockClient = MockGoogleDriveClient();

// ❌ Don't mock the class under test
final mockService = MockBackupService(); // Wrong!
```

### Use `any` for flexible matching

```dart
// When you don't care about specific arguments
when(mock.save(any)).thenAnswer((_) async => true);

// When you need specific argument
when(mock.save(argThat(isA<StoryDbModel>()))).thenAnswer((_) async => true);
```

### Reset mocks between tests

```dart
setUp(() {
  mockRepository = MockStoryRepository();
  // Fresh mock for each test
});
```

## See Also

- [Testing Basics](testing-basics.md) - Test patterns and structure
- [Test Coverage](test-coverage.md) - Coverage and best practices
