# Icons

**Always use `SpIcons` instead of direct icon imports.**

## Usage

```dart
// ❌ Don't
Icon(Icons.edit)
Icon(CupertinoIcons.pencil)

// ✅ Do
Icon(SpIcons.edit)
```

## How SpIcons Works

```dart
// lib/widgets/sp_icons.dart
class SpIcons {
  static const IconData edit = kIsCupertino
    ? CupertinoIcons.square_pencil
    : Icons.edit_outlined;
}
```

## Icon Sources

1. **Cupertino** → iOS-style icons
2. **Material** → Android-style icons
3. **MdiIcons** → `material_design_icons_flutter` package

## Adding New Icons

**Step 1**: Check `kIsCupertino` constant

```dart
// core/constants/app_constants.dart
const bool kIsCupertino = ...; // Platform check
```

**Step 2**: Add to SpIcons

```dart
// widgets/sp_icons.dart
static const IconData myNewIcon = kIsCupertino
  ? CupertinoIcons.my_icon_ios
  : Icons.my_icon_android;

// Or use MdiIcons when needed
static final IconData myMdiIcon = MdiIcons.myIcon;
```

**Step 3**: Use in code

```dart
Icon(SpIcons.myNewIcon)
```

## Icon Reference

Common `SpIcons` used in app:

| Icon                  | Usage                |
| --------------------- | -------------------- |
| `SpIcons.edit`        | Edit actions         |
| `SpIcons.delete`      | Delete actions       |
| `SpIcons.save`        | Save actions         |
| `SpIcons.share`       | Share actions        |
| `SpIcons.search`      | Search functionality |
| `SpIcons.setting`     | Settings             |
| `SpIcons.tag`         | Tags                 |
| `SpIcons.archive`     | Archive              |
| `SpIcons.star`        | Favorites            |
| `SpIcons.lock`        | Security             |
| `SpIcons.cloudUpload` | Backup               |
| `SpIcons.calendar`    | Calendar             |
| `SpIcons.photo`       | Photos               |

See [sp_icons.dart](../../lib/widgets/sp_icons.dart) for full list.
