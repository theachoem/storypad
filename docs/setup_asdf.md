# Setup ASDF

StoryPad uses **asdf** to manage versions for Flutter, Java, and Ruby. If you are using a different version manager, you can ignore this documentation & install the tools based on the versions specified in the `.tool-versions` file in the project root.

Follow the steps below to install the tools in the correct order.

## I. Java (for Android)

To install **Java** using **asdf**, follow these steps:

```sh
asdf plugin add java
asdf install java openjdk-21
```

To verify the installation:

```sh
$ which java
~/.asdf/shims/java

$ java --version
openjdk 21 2023-09-19
```

### Troubleshooting

If `which java` returns a different path than `~/.asdf/shims/java`, ensure that you add `$JAVA_HOME` to your shell configuration. Refer to [this guide](https://github.com/halcyon/asdf-java?tab=readme-ov-file#java_home) for details on how to configure `$JAVA_HOME`.

### References

- Check the Java LTS version: [Java SE Support Roadmap](https://www.oracle.com/java/technologies/java-se-support-roadmap.html)
- Check `gradle-wrapper.properties` compatibility with Java version: [Gradle Compatibility Guide](https://docs.gradle.org/current/userguide/compatibility.html)
- Check `com.android.application` plugin compartible with gradle. [Android Gradle Plugin](https://developer.android.com/build/releases/gradle-plugin#updating-gradle)
- Check `org.jetbrains.kotlin.android` plugin compartible version with gradle. [Kotlin Compatibility](https://docs.gradle.org/current/userguide/compatibility.html#kotlin)

---

## II. Ruby (for IOS)

Ruby is used for manage CocoaPods dependency for IOS. To install **Ruby** using **asdf**, run the following:

```sh
asdf plugin add ruby
asdf install ruby 3.3.5
```

Verify the installation & install cocoapods:

```sh
$ which ruby
~/.asdf/shims/ruby

$ ruby --version
ruby 3.3.5 (2024-09-03 revision ef084cc8f4) [arm64-darwin23]

$ which gem
~/.asdf/shims/gem

$ gem install cocoapods
```

## III. Flutter

To install Flutter using **asdf**, run the following commands:

```sh
asdf plugin add flutter
asdf install flutter 3.32.0-stable
```

Additional Setup:

- **Install FlutterFire CLI** (required for iOS crash symbol uploads):

  ```sh
  dart pub global activate flutterfire_cli
  ```

- **Set `FLUTTER_ROOT`** in your shell initial such as `.zshrc` (needed for Xcode scripts like `firebase upload-crashlytics-symbols`):
  ```sh
  export FLUTTER_ROOT="$(asdf where flutter)"
  ```

To verify the installation:

```sh
$ which flutter
~/.asdf/shims/flutter

$ flutter --version
Flutter 3.32.0 • channel stable • https://github.com/flutter/flutter.git

$ flutter doctor
```

### Troubleshooting

1. **Error: `jq: command not found`**

   If you encounter the following error during installation:

   ```sh
   ~/.asdf/plugins/flutter/bin/install: line 25: jq: command not found
   ```

   Simply install `jq` using Homebrew:

   ```sh
   brew install jq
   ```

   Then, uninstall and reinstall Flutter:

   ```sh
   asdf uninstall flutter 3.32.0-stable
   asdf install flutter 3.32.0-stable
   ```

### References

- [https://github.com/asdf-community/asdf-flutter](https://github.com/asdf-community/asdf-flutter)
