# Other Flavors

```s
./flutterfire.sh --spooky
./flutterfire.sh --storypad
./flutterfire.sh --community

flutter run --flavor spooky --dart-define-from-file=env/spooky.json --target=lib/main_spooky.dart
flutter run --flavor storypad --dart-define-from-file=env/storypad.json --target=lib/main_storypad.dart

flutter build apk --release --flavor spooky --dart-define-from-file=env/spooky.json --target=lib/main_spooky.dart
flutter build apk --release --flavor storypad --dart-define-from-file=env/storypad.json --target=lib/main_storypad.dart

flutter build appbundle --release --flavor spooky --dart-define-from-file=env/spooky.json --target=lib/main_spooky.dart
flutter build appbundle --release --flavor storypad --dart-define-from-file=env/storypad.json --target=lib/main_storypad.dart
```
