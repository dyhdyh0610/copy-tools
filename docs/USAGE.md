# Copy Tools Usage

## Installed App

The packaged app is installed at:

`/Applications/Copy Tools.app`

Open it from Finder or Spotlight. It runs as a menu bar app and does not show a Dock icon.

## Shortcut

Default shortcut:

`Option + C`

This opens the clipboard history panel.

## Basic Flow

1. Copy text or an image in any app.
2. Press `Option + C`.
3. Search or filter history.
4. Select an item.
5. Press Enter or click the copy button.

Copy Tools only copies the selected item back to the clipboard. It does not auto-paste into the active app.

## Settings

Open settings from the menu bar item.

Available settings:

- Retention period: 24h, 7 days, or 30 days.
- Item limit: 100 to 2000.
- Close panel after copy.
- Launch at login.
- Pause recording.
- Favorites participate in cleanup.
- Clear non-favorite history.
- Clear all history.

## Rebuild And Reinstall

From the project folder:

```sh
scripts/install_app.sh
```

This rebuilds the release binary, creates `dist/Copy Tools.app`, and copies it to `/Applications/Copy Tools.app`.

## Verification

Standard test suite:

```sh
swift test
```

On Command Line Tools installs that do not include Swift Testing, this is a build sanity check. Use the standalone core checks below for assertions in that environment.

Standalone core checks:

```sh
swift run CopyToolsChecks
```

Build only:

```sh
swift build --product CopyTools
```
