# Testing Basics

**Test structure, principles, and patterns.**

## Test Structure

```
test/
├── core/
│   ├── objects/           # Data object tests
│   ├── repositories/      # Repository tests
│   ├── services/          # Service tests
│   ├── exceptions/        # Exception tests
│   ├── types/             # Type tests
│   └── utils/             # Utility tests
└── flutter_test_config.dart  # Test configuration
```

## Testing Principles

1. **Test business logic** → Focus on ViewModels, Services, Repositories
2. **Mock dependencies** → Use `mockito` for mocking
3. **Test edge cases** → Error scenarios, null values, boundary conditions
4. **Keep tests fast** → Unit tests should run quickly
5. **Test behavior, not implementation** → Focus on what, not how

## Unit Tests

### Testing ViewModels

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('EditStoryViewModel', () {
    late EditStoryViewModel viewModel;
    late MockStoryRepository mockRepository;

    setUp(() {
      mockRepository = MockStoryRepository();
      viewModel = EditStoryViewModel(repository: mockRepository);
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('should save story successfully', () async {
      // Arrange
      final story = StoryDbModel(title: 'Test');
      when(mockRepository.save(story)).thenAnswer((_) async => story);

      // Act
      await viewModel.saveStory(story);

      // Assert
      verify(mockRepository.save(story)).called(1);
      expect(viewModel.isSaving, false);
    });

    test('should handle save error', () async {
      // Arrange
      when(mockRepository.save(any)).thenThrow(Exception('Save failed'));

      // Act & Assert
      expect(
        () => viewModel.saveStory(StoryDbModel()),
        throwsException,
      );
    });
  });
}
```

### Testing Services

```dart
void main() {
  group('BackupService', () {
    late BackupService service;
    late MockGoogleDriveClient mockClient;

    setUp(() {
      mockClient = MockGoogleDriveClient();
      service = BackupService(client: mockClient);
    });

    test('should upload backup successfully', () async {
      // Arrange
      when(mockClient.upload(any)).thenAnswer((_) async => 'file_id');

      // Act
      final result = await service.uploadBackup();

      // Assert
      expect(result.isSuccess, true);
      verify(mockClient.upload(any)).called(1);
    });
  });
}
```

### Testing Repositories

```dart
void main() {
  group('StoryRepository', () {
    late StoryRepository repository;
    late Box<StoryDbModel> mockBox;

    setUp(() {
      mockBox = MockBox();
      repository = StoryRepository(box: mockBox);
    });

    test('should return all stories', () {
      // Arrange
      final stories = [StoryDbModel(title: 'Story 1')];
      when(mockBox.getAll()).thenReturn(stories);

      // Act
      final result = repository.getAll();

      // Assert
      expect(result, stories);
      verify(mockBox.getAll()).called(1);
    });
  });
}
```

## Widget Tests

```dart
void main() {
  testWidgets('EditStoryView should render correctly', (tester) async {
    // Arrange
    final viewModel = EditStoryViewModel();

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: viewModel,
          child: EditStoryView(),
        ),
      ),
    );

    // Assert
    expect(find.text('Edit Story'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });
}
```

## Integration Tests

Location: `integration_test/` (if needed)

**Pattern:** Use `IntegrationTestWidgetsFlutterBinding`, test full user flows

## Example Tests

See: `test/core/exceptions/`, `test/core/types/`, `test/core/utils/`, `test/core/services/`

## See Also

- [Mocking](mocking.md) - Mockito patterns
- [Test Coverage](test-coverage.md) - Coverage and best practices
- [Commands](../guides/commands.md) - Test commands
