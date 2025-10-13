# Test Coverage

**Coverage goals, best practices, and debugging.**

## Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/services/backup_service_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Coverage Goals

- **Core logic**: 80%+ coverage
- **Services**: 80%+ coverage
- **Repositories**: 80%+ coverage
- **ViewModels**: 70%+ coverage
- **UI**: 50%+ coverage (focus on critical paths)

## Testing Best Practices

### Do's ✅

- Test one thing per test
- Use descriptive test names
- Follow Arrange-Act-Assert pattern
- Mock external dependencies
- Test error scenarios
- Clean up resources in `tearDown`
- Use `setUp` for common initialization

### Don'ts ❌

- Don't test Flutter framework code
- Don't test third-party packages
- Don't make tests dependent on each other
- Don't test implementation details
- Don't skip error scenarios
- Don't leave failing tests

## Test Naming

```dart
// ✅ Good - Descriptive
test('should save story successfully when valid data provided', () {});
test('should throw exception when repository fails', () {});
test('should update loading state during save operation', () {});

// ❌ Bad - Vague
test('save test', () {});
test('test 1', () {});
test('it works', () {});
```

## Arrange-Act-Assert Pattern

```dart
test('should calculate total correctly', () {
  // Arrange - Set up test data
  final calculator = Calculator();
  final numbers = [1, 2, 3, 4, 5];

  // Act - Execute the code under test
  final result = calculator.sum(numbers);

  // Assert - Verify the result
  expect(result, 15);
});
```

## Testing Error Scenarios

```dart
test('should handle null input gracefully', () {
  final service = MyService();

  expect(
    () => service.process(null),
    throwsA(isA<ArgumentError>()),
  );
});

test('should return error result when operation fails', () async {
  // Arrange
  when(mockRepository.save(any)).thenThrow(Exception('Failed'));

  // Act
  final result = await service.save(data);

  // Assert
  expect(result.isFailure, true);
  expect(result.error, isNotNull);
});
```

## Debugging Tests

### Run single test

```bash
flutter test test/my_test.dart --name "test name"
```

### VSCode debugging

1. Set breakpoint in test
2. Run > Start Debugging
3. Step through code

### Print debugging

```dart
test('debug test', () {
  print('Value: $value');
  debugPrint('Debug info: $info');

  expect(value, expectedValue);
});
```

## CI/CD

See `.github/workflows/ci.yml` - runs `flutter test --coverage` on PRs and commits

## Common Issues

### Tests pass locally but fail in CI

- Check for hardcoded paths
- Verify timezone-independent date handling
- Ensure no dependency on local files

### Flaky tests

- Avoid `DateTime.now()` - use injected time
- Don't depend on test execution order
- Mock all external dependencies

### Slow tests

- Use unit tests over widget/integration tests
- Mock expensive operations
- Avoid real network calls

## See Also

- [Testing Basics](testing-basics.md) - Test patterns
- [Mocking](mocking.md) - Mockito usage
- [Commands](../guides/commands.md) - Test commands
