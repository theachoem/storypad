# Home Quick Action Icons

Guide for managing native home quick action icons used by the `quick_actions` plugin.

## Scope

These icons are **native resources**, not `SpIcons`.

- Android: PNG files in `android/app/src/main/res/drawable-*/`
- iOS: asset catalogs in `ios/Runner/Assets.xcassets/`

## Android Workflow (Material Icons + appicon.co)

The background, tint, and padding are all handled by XML — the PNG just needs to be a **black icon on transparent background** (default Google Fonts export).

### Steps

1. Go to Google Fonts Icons: <https://fonts.google.com/icons>
2. Pick the **Material Icons** style (not Material Symbols) to avoid variable weight/style mismatches.
3. Switch to **PNG** format and download at **1000×1000** size.
4. Go to <https://www.appicon.co/#app-icon> and upload the PNG.
5. Download the generated ZIP — it contains `mipmap-mdpi/`, `mipmap-hdpi/`, `mipmap-xhdpi/`, `mipmap-xxhdpi/`, `mipmap-xxxhdpi/` folders.
6. Rename the file inside each folder to `ic_qa_<name>.png` (e.g. `ic_qa_take_photo.png`).
7. Copy each file to the matching `drawable-*` folder in the project:

| Downloaded folder | Copy to                                      |
| ----------------- | -------------------------------------------- |
| `mipmap-mdpi/`    | `android/app/src/main/res/drawable-mdpi/`    |
| `mipmap-hdpi/`    | `android/app/src/main/res/drawable-hdpi/`    |
| `mipmap-xhdpi/`   | `android/app/src/main/res/drawable-xhdpi/`   |
| `mipmap-xxhdpi/`  | `android/app/src/main/res/drawable-xxhdpi/`  |
| `mipmap-xxxhdpi/` | `android/app/src/main/res/drawable-xxxhdpi/` |

### How the XML layer works

Each icon has two XML files that the `quick_actions` plugin resolves by name (`qa_<name>`):

- **`drawable/qa_<name>.xml`** — `<layer-list>` fallback for API 24–25
- **`drawable-v26/qa_<name>.xml`** — `<adaptive-icon>` for API 26+, with `<monochrome>` for Android 13+ Themed Icons

Both XMLs reference `@drawable/ic_qa_<name>` (the PNG), apply `android:tint="@color/shortcut_icon_foreground"` to color the glyph, and use `android:inset="30%"` for padding. Colors come from `@color/shortcut_icon_background` (`#F5F5F5`) and `@color/shortcut_icon_foreground` (`#1F1F1F`) in `values/colors.xml`.

### Icon names

- `qa_new_story`, `qa_take_photo`, `qa_record_voice`, `qa_template`, `qa_tag`

### Notes

- PNG files use the `ic_` prefix (e.g. `ic_qa_new_story.png`) to avoid a `ResourceCycle` lint error — the XML and PNG cannot share the same name.
- Do **not** bake a background into the PNG — keep it as the default transparent export from Google Fonts. The XML handles the background.
- To change icon colors globally, update `shortcut_icon_background` and `shortcut_icon_foreground` in `android/app/src/main/res/values/colors.xml`.

## iOS Workflow (SF Symbols + Figma)

SF Symbols exports are not truly square — dimensions vary by symbol shape. To ensure consistent sizing, bring them into Figma and set a fixed square canvas, then adjust padding per icon to taste (typically ~4px).

### Steps

1. Open the **SF Symbols** app (macOS).
2. Search for the symbol you need, select it, and export via **Copy Image as…**:
   - **Point Size:** `25`, **Symbol Scale:** `Medium`, **Pixel Scale:** `3`
3. Paste the exported PNG into **Figma**.
4. Resize the frame to exactly **25×25** (1x canvas size).
5. Adjust padding per icon as needed (typically ~4px) so each symbol feels optically balanced.
6. Export at **1x**, **2x**, and **3x** — Figma names them `icon.png`, `icon@2x.png`, `icon@3x.png`.
7. Place the three exported PNGs into the imageset folder, using the existing filenames:

| Imageset                    | 1x file                  | 2x file                     | 3x file                     |
| --------------------------- | ------------------------ | --------------------------- | --------------------------- |
| `qa_take_photo.imageset/`   | `camera.png`             | `camera@2x.png`             | `camera@3x.png`             |
| `qa_new_story.imageset/`    | `pencil.and.outline.png` | `pencil.and.outline@2x.png` | `pencil.and.outline@3x.png` |
| `qa_template.imageset/`     | `lightbulb.png`          | `lightbulb@2x.png`          | `lightbulb@3x.png`          |
| `qa_record_voice.imageset/` | `microphone.png`         | `microphone@2x.png`         | `microphone@3x.png`         |
| `qa_tag.imageset/`          | `tag.png`                | `tag@2x.png`                | `tag@3x.png`                |

### Expected pixel dimensions

| Scale | Size     |
| ----- | -------- |
| 1x    | 25×25 px |
| 2x    | 50×50 px |
| 3x    | 75×75 px |

### Notes

- Keep icons monochrome (white on transparent) for correct quick action rendering.
- The `Contents.json` in each imageset already references these filenames — do not rename the files.

## Validation Checklist

1. Ensure native icon names match mappings used by quick action model/service.
2. Rebuild app.
3. Long-press app icon on Android/iOS and confirm each shortcut icon renders correctly.
