# StoryPad 📝

<!-- ![cover](https://repository-images.githubusercontent.com/444136870/43a054a0-50ad-47d7-a680-4a12507a77d2) -->

First journal with Material 3 design! StoryPad is a minimalist design application to write stories, journals, notes, diaries, todo, etc. We offer a variety of features that you can expect for your daily usage.

<!-- [![App Store](https://img.shields.io/badge/App_Store-0D96F6?style=for-the-badge&logo=app-store&logoColor=white)](https://apps.apple.com/us/app/spooky/id1629372753?platform=iphone) -->

[![Play Store](https://img.shields.io/badge/Google_Play-414141?style=for-the-badge&logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=com.tc.writestory)

## Installation

Before getting started, ensure you have the following tools:

- Java: 21 [(LTS)](https://www.oracle.com/java/technologies/java-se-support-roadmap.html) (for Android)
- Ruby: 3.3.5 (for IOS)
- Flutter: 3.27.4

If you're using asdf, refer to this [guide](asdf.md). Otherwise, you can install above versions manually with fvm, rvm, rbenv or others.

## Setup

For easy setup and running, the GoogleService-Info.plist, google-services.json, and Dart defines are provided directly in this repo. Simply run the project with:

```s
flutter run --flavor community --dart-define-from-file=env/community.json --target=lib/main_community.dart
```

## License

StoryPad is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.
