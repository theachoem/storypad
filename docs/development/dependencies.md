# Dependencies

## Dependency Policy

**⚠️ Avoid adding new dependencies unless truly necessary.**

Before adding a package:

1. Check if functionality can be implemented with existing packages
2. Evaluate package maintenance, popularity, and compatibility
3. Consider bundle size impact
4. Ask maintainer if uncertain

## Core Dependencies

### State Management

- **provider** `^6.1.4` → Global & view state management
- Pattern: `ChangeNotifier` + `Provider`

### Database

- **objectbox** `^5.0.0` → Local database (primary)
- **sqflite** `^2.4.2` → SQLite (legacy/specific use cases)
- **shared_preferences** `^2.5.3` → Simple key-value storage

### UI Components

- **adaptive_dialog** (local package) → Platform-adaptive dialogs
- **flutter_slidable** `^4.0.0` → Swipe actions
- **flutter_staggered_grid_view** `^0.7.0` → Grid layouts
- **dismissible_page** `^1.0.2` → Dismissible pages
- **animations** `^2.0.11` → Smooth transitions

### Icons & Fonts

- **cupertino_icons** `^1.0.8` → iOS icons
- **material_design_icons_flutter** `^7.0.7296` → Extended Material icons
- **google_fonts** `^6.2.1` → 1300+ fonts

### Rich Text Editor

- **flutter_quill** (custom fork) → Rich text editing
- Fork: `github.com/theachoem/flutter-quill.git`
- Reason: Custom modifications for StoryPad needs

### Images & Media

- **cached_network_image** `^3.4.1` → Image caching
- **image_picker** `^1.1.2` → Pick images
- **photo_view** `^0.15.0` → Image viewer
- **flutter_svg** `^2.1.0` → SVG support

### Audio

- **audio_service** `^0.18.18` → Background audio
- **just_audio** `^0.10.4` → Audio playback

### Firebase

- **firebase_core** `^4.0.0` → Firebase SDK
- **firebase_analytics** `^12.0.0` → Analytics
- **firebase_crashlytics** `^5.0.1` → Crash reporting
- **firebase_remote_config** `^6.0.0` → Remote config
- **firebase_storage** `^13.0.0` → Cloud storage
- **cloud_firestore** `^6.0.2` → Firestore database

### Google Services

- **google_sign_in** `^6.3.0` → Google authentication
- **googleapis** `^15.0.0` → Google Drive API

### Security

- **flutter_secure_storage** `^10.0.0-beta.4` → Secure storage
- **local_auth** `^2.3.0` → Biometric authentication

### Localization

- **easy_localization** `^3.0.7+1` → i18n support
- **flutter_localizations** (SDK) → Flutter localization

### Utilities

- **device_info_plus** `^12.1.0` → Device information
- **package_info_plus** `^9.0.0` → App information
- **share_plus** `^12.0.0` → Share functionality
- **file_picker** `^10.1.9` → File picking
- **flutter_custom_tabs** `^2.3.0` → Custom tabs
- **visibility_detector** `^0.4.0+2` → Visibility detection
- **fuzzy** `^0.5.1` → Fuzzy search
- **html_character_entities** `^1.0.0+1` → HTML entities

### Monetization

- **purchases_flutter** `^9.6.1` → In-app purchases
- **in_app_review** `^2.0.10` → App review prompts
- **in_app_update** `^4.2.3` → In-app updates (Android)

### Theme

- **dynamic_color** `^1.8.1` → Material You colors

### Markdown

- **flutter_markdown** `^0.7.7` → Markdown rendering

## Dev Dependencies

### Code Generation

- **build_runner** `^2.4.15` → Code generation runner
- **json_serializable** `^6.9.5` → JSON serialization
- **copy_with_extension_gen** `^9.1.1` → CopyWith generation
- **objectbox_generator** → ObjectBox code generation
- **flutter_gen_runner** `^5.8.0` → Asset generation

### Testing

- **flutter_test** (SDK) → Testing framework
- **mockito** `^5.4.6` → Mocking

### Tooling

- **flutter_lints** `^6.0.0` → Linting rules
- **flutter_launcher_icons** `^0.14.3` → App icon generation
- **flutter_native_splash** `^2.4.6` → Splash screen generation
- **csv** `^6.0.0` → CSV parsing (localization)

## Usage Patterns

See [quick-reference.md](../guides/quick-reference.md) for common usage patterns.

## Adding Dependencies

1. Check if truly necessary (evaluate alternatives)
2. Add to `pubspec.yaml`
3. Run `flutter pub get`
4. Document in this file
