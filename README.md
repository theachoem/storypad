# StoryPad - Open Source Diary & Journal App

[![CI](https://github.com/theachoem/storypad/actions/workflows/ci.yml/badge.svg)](https://github.com/theachoem/storypad/actions/workflows/ci.yml) [![Build](https://github.com/theachoem/storypad/actions/workflows/build.yml/badge.svg)](https://github.com/theachoem/storypad/actions/workflows/build.yml) [![GitHub stars](https://img.shields.io/github/stars/theachoem/storypad?style=social)](https://github.com/theachoem/storypad/stargazers) [![GitHub license](https://img.shields.io/github/license/theachoem/storypad)](LICENSE) [![GitHub issues](https://img.shields.io/github/issues/theachoem/storypad)](https://github.com/theachoem/storypad/issues)

📝 **StoryPad** is a beautiful, privacy-first, open source journal & diary app designed for people who value simplicity, minimalism, and control over their personal data.

Capture your _notes, thoughts, emotions, workouts, travels, stories, novels, poems, or anything that matters to you_ on a **single continuous timeline**.

> No folders. No tabs. Just your life, beautifully organized. Your story flows like life does: naturally.

[![Play Store](https://img.shields.io/badge/Google_Play-414141?style=for-the-badge&logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=com.tc.writestory) [![App Store](https://img.shields.io/badge/App_Store-0D96F6?style=for-the-badge&logo=app-store&logoColor=white)](https://testflight.apple.com/join/y2F3vBUx)

## 🌟 <StoryPad> Key Features

- **Timeline journaling** – your life flows naturally, no folders or tabs
- **Fully customizable writing** – bold, lists, checkboxes, colors, 1300+ Google Fonts
- **Throwback memories** – see what you wrote on this day years ago
- **Photo memories** – add multiple photos per page with custom layout
- **Feelings & moods tracker** – 45+ emotions, history & calendar view
- **Multi-page entries** – perfect for novels, prompts, or daily notes
- **Tags, stars & search** – keep your story organized and easy to find
- **Privacy first** – PIN, FaceID, fingerprint lock; data stays on your device
- **Backup & sync** – private Google Drive sync & offline local export
- **Themes & customization** – 20+ color themes, dark/light mode, fonts & layouts
- **Export & share** – text, markdown, or full backups
- **Available in 20+ languages** – and fully open source for transparency

## 📸 Screenshots

| 🚀                                                                                                                                  | 😍                                                                                                                                  | ✨                                                                                                                                  |
| ----------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| ![image1](https://play-lh.googleusercontent.com/xDkw2GGMIeH5errCdVBb-OgStPj53tEY7QuJeOl-fBu3S37Ca814KQ6lhhyRfgK2yTw=w1052-h592-rw)  | ![image2](https://play-lh.googleusercontent.com/sotRS8j1BeriuDLjG_oR7aCyZ8gtMGatTpyTicSKCjMCQ62YGnt9xHIyjXugAAfI-eE=w1052-h592-rw)  | ![image3](https://play-lh.googleusercontent.com/Ha_GhuSk2EuKebipFmAqw7BROe1yYeixivcxMoOkG2zK5BfXg5our427zc2P5KhU86Q=w1052-h592-rw)  |
| ![image4](https://play-lh.googleusercontent.com/k4CfgonDMKBb2RdHbBMH2BKm6V5nXKJcBvxljvideS30XDDzqsYSDlMDkIHr0W3VB24s=w1052-h592-rw) | ![image5](https://play-lh.googleusercontent.com/pwRsr46JHtAwrSRVkXU70f6n7fPgd4DYb8fj1XGFGjMg2_DEbwdrNunP4k_0xNwWMDix=w1052-h592-rw) | ![image6](https://play-lh.googleusercontent.com/RYgs_fZvK1J7APEW0O9WRN1y_hIeUeTj838NMDefYWWPT7Rp79fMppSFnLxweU16lYno=w1052-h592-rw) |

## ⚙️ Setup & Run <StoryPad>

Before getting started, ensure you have the following tools:

- Java: 21 [(LTS)](https://www.oracle.com/java/technologies/java-se-support-roadmap.html) (for Android)
- Ruby: 3.3.5 (for IOS)
- Flutter: 3.29.0

> If you're using asdf, refer to this [guide](docs/setup_asdf.md). Otherwise, you can install above versions manually with fvm, rvm, rbenv or others.

For easy setup and running, the GoogleService-Info.plist, google-services.json, and Dart defines are provided directly in this repo. Simply run the project with:

```s
flutter run --flavor community --dart-define-from-file=configs/community.json --target=lib/main_community.dart
```

## 🛠 <StoryPad> Project Overview

StoryPad is designed with simplicity in mind, both in its UI and codebase. We aimed to keep the code understandable while staying true to Flutter's principles.

### 1. State Management:

StoryPad uses Provider and Stateful widgets to manage its state, distinctly organized into three levels to avoid confusion:

- Global State: Managed by [ProviderScope](lib/provider_scope.dart), disposed when the app closes.
- View State: Managed by [ViewModelProvider](lib/widgets/view/view_model_provider.dart), disposed when the page closes.
- Widget State: Managed by Stateful widgets, where the widget itself controls its own state and is disposed when removed from the tree.

### 2. MVVM Pattern:

StoryPad leverages the MVVM (Model-View-ViewModel) pattern while each view is composed of three to four key files:

- Model (optional): Represents the data structure, e.g., StoryDbModel.
- View: Constructs the view model and builds the UI content, e.g., EditStoryView.
- ViewContent: Displays the actual UI, keeping the visual layout separate from business logic, e.g., EditStoryContent.
- ViewModel: Manages business logic, provides data & operations to the view, keeping the UI free from unnecessary logic, e.g., EditStoryViewModel.

### 3. Local Database:

StoryPad uses ObjectBox as the local database solution for persistent data storage. ObjectBox provides fast, efficient, and scalable database operations with rich search capabilities, making it ideal for mobile apps that require high-performance data handling.

## 🔧 CI/CD & Development

StoryPad uses GitHub Actions for continuous integration and deployment:

- **CI Workflow**: Runs tests, linting, and code analysis on every pull request
- **Build Workflow**: Creates Android APK and App Bundle artifacts for all flavors
- **Dependencies**: Weekly security checks and dependency updates
- **Release**: Automated release creation with build artifacts when tags are pushed

### Development Commands

```bash
# Run the community flavor
bin/dev --community

# Run tests
flutter test

# Build APK for community flavor  
bin/build_apk --community

# Code analysis
flutter analyze

# Format code
dart format .
```

All workflows are configured to use the exact tool versions specified in `.tool-versions`:
- Java 21, Ruby 3.3.5, Flutter 3.35.1-stable

## 🤝 Learn & Contribute

Feel free to clone the StoryPad repository and explore the code. It’s a great resource for learning how to build efficient, maintainable mobile apps with Flutter. You can also contribute improvements or new features, helping enhance the project for everyone. Raise an issue if you need any support.

A big thank you to the maintainers of the packages StoryPad relies on - without their work, StoryPad wouldn’t be possible. You can view all the dependencies in the [pubspec.yaml](pubspec.yaml) file.

## 📄 License

StoryPad is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.

We chose the GPL license to ensure that StoryPad’s source code remains free and open. Anyone can use, study, modify, and distribute it - but any modifications must also remain open-source under the same license.

🌐 **Website:** [StoryPad.me](https://storypad.me) - Explore the official StoryPad website for features, screenshots, and more.  
💻 **App Source Code:** [github.com/theachoem/storypad](https://github.com/theachoem/storypad)  
🖥 **Website Source Code:** [github.com/theachoem/storypad.me](https://github.com/theachoem/storypad.me)
