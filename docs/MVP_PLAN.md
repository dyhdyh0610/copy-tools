# Copy Tools MVP Implementation Plan

## Phase 1: Project Foundation

- Create Swift Package based macOS app skeleton.
- Add SwiftUI app entry point.
- Add AppKit app delegate for menu bar, global shortcut, and activation policy.
- Add core folders:
  - `Models`
  - `Services`
  - `Views`
  - `Support`
  - `Tests`

Deliverable:

- App can build from the command line.
- App can launch as a local menu bar process.

## Phase 2: Data Model And Storage

- Define `ClipboardItem`.
- Define `ClipboardItemKind`.
- Define `AppSettings`.
- Add SQLite-backed `HistoryStore`.
- Store:
  - item id
  - content hash
  - kind
  - text content
  - image path
  - thumbnail path
  - source app name
  - source bundle id
  - created time
  - updated time
  - favorite state
  - favorite time

Deliverable:

- Insert, update duplicate, query, favorite, delete, and cleanup APIs exist.
- Core storage can be unit tested without UI.

## Phase 3: Clipboard Monitoring

- Poll `NSPasteboard.general.changeCount`.
- Ignore clipboard writes triggered by Copy Tools itself.
- Record text content if non-empty and below 1 MB.
- Record PNG/JPG/JPEG images.
- Convert WebP to PNG if detected and supported by system image APIs.
- Ignore images above 20 MB.
- Capture active app name and bundle id.

Deliverable:

- Clipboard text and supported images become history records.

## Phase 4: History Panel

- Build Raycast/Spotlight-style floating panel.
- Add search field.
- Add filters: All, Favorites, Images, Text, App.
- Add unified item list.
- Text rows show up to 3 lines.
- Image rows show 96x96 thumbnail.
- Selection shows full text or larger image preview.
- Add copy button.
- Add favorite button.
- Add single-item delete icon.
- Add multi-select delete mode.

Deliverable:

- User can find, preview, copy, favorite, and delete history from the panel.

## Phase 5: Copy And Drag

- Copy text back to `NSPasteboard`.
- Copy image back to `NSPasteboard`.
- Close panel after copy by default.
- Show lightweight copy-success feedback.
- Support dragging image items out of the panel.

Deliverable:

- Existing text and images can be reused outside Copy Tools.

## Phase 6: Settings And First Launch

- Add settings window.
- Add first-launch guide.
- Persist:
  - retention period
  - item limit
  - shortcut
  - close after copy
  - launch at login
  - pause/resume
  - favorites cleanup behavior
- Add clear non-favorites and clear all actions.

Deliverable:

- User can configure the MVP without editing files.

## Phase 7: Cleanup And Notifications

- Run cleanup after insert and on launch.
- Enforce retention period.
- Enforce item limit.
- Respect favorite cleanup setting.
- Send notifications for:
  - copy success
  - oversized content ignored
  - batch delete completed

Deliverable:

- History stays within user-selected limits.

## Phase 8: Tests

Core unit tests:

- Duplicate merge updates timestamp instead of inserting.
- Retention cleanup deletes expired normal items.
- Limit cleanup deletes oldest normal items.
- Favorite cleanup setting is respected.
- Empty text is ignored.
- Oversized text and image are ignored.
- Search filters text items.
- Favorites sort by favorite time descending.

Deliverable:

- Core rule tests pass from the command line.

## Initial Implementation Scope

The first code pass should create a buildable skeleton with:

- Menu bar app entry.
- Global shortcut manager placeholder.
- Clipboard monitor placeholder.
- SQLite store structure.
- SwiftUI history panel.
- SwiftUI settings view.
- Basic unit tests for pure model rules.

The first pass does not need to fully implement every UI interaction, but it should establish stable boundaries so each phase can be completed without rewrites.
