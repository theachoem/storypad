# Other Flavors

```bash
./flutterfire.sh --spooky
./flutterfire.sh --storypad
./flutterfire.sh --community

# all in one
./flutterfire.sh --spooky && ./flutterfire.sh --storypad && ./flutterfire.sh --community

flutter run --flavor spooky --dart-define-from-file=env/spooky.json --target=lib/main_spooky.dart
flutter run --flavor storypad --dart-define-from-file=env/storypad.json --target=lib/main_storypad.dart

flutter build apk --release --flavor spooky --dart-define-from-file=env/spooky.json --target=lib/main_spooky.dart && flutter build apk --release --flavor storypad --dart-define-from-file=env/storypad.json --target=lib/main_storypad.dart

flutter build appbundle --release --flavor spooky --dart-define-from-file=env/spooky.json --target=lib/main_spooky.dart && flutter build appbundle --release --flavor storypad --dart-define-from-file=env/storypad.json --target=lib/main_storypad.dart
```

## Usefuls commands

```bash
# Sort pubspec.yaml
flutter pub run pubspec_dependency_sorter

# Upgrade
flutter pub upgrade --major-versions

# Check outdate packages
flutter pub outdated
```

## Get Noto Emoji Lottie Latest List

```js
// https://googlefonts.github.io/noto-emoji-animation
// Make sure to scroll to bottom to load everything first.

const lottieUrls = Array.from(document.getElementsByTagName("button"))
  .map((button) => {
    // Check if the button has both img and span elements as children
    const img = button.querySelector("img");
    const span = button.querySelector("span");

    // Skip this iteration if either img or span is not found
    if (!img || !span) return;

    // Proceed if both are found
    const src = img.src.replace("/emoji.svg", "/lottie.json");
    const label = span.textContent;

    return { label, src };
  })
  .filter((item) => item !== undefined);

const uniqueUrls = Array.from(
  new Map(lottieUrls.map((item) => [item.label, item])).values()
);

const copyToClipboard = async () => {
  try {
    await navigator.clipboard.writeText(JSON.stringify(uniqueUrls));
    console.log("Copied to clipboard:", uniqueUrls);
  } catch (err) {
    console.error("Failed to copy:", err);
  }
};

// Click this button to copy
Object.assign(document.body.appendChild(document.createElement("button")), {
  textContent: "Copy Lottie URLs",
  style:
    "position:fixed; top:10px; right:10px; z-index:9999; padding:5px 10px;",
  onclick: copyToClipboard,
});
```
