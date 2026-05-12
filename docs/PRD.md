# Copy Tools PRD

## 1. Product Goal

Copy Tools is a local macOS clipboard history tool. It records text and image clipboard history for a configurable period, then lets the user quickly recall an item and copy it back to the system clipboard.

The first version is a local MVP for personal testing. It does not include public distribution, signing, notarization, auto-update, account login, or cloud sync.

## 2. Target Platform

- Platform: macOS only.
- Form factor: menu bar app.
- Technology: Swift/SwiftUI with AppKit where needed.
- Default global shortcut: `Option + C`.

## 3. Core User Flow

1. App runs in the menu bar.
2. User presses `Option + C`.
3. A Raycast/Spotlight-style floating history panel opens.
4. User searches, filters, previews, or selects a clipboard item.
5. User copies the selected text or image back to the system clipboard.
6. The app does not automatically paste into the active app.
7. By default, the panel closes after copy. A setting can keep it open.

## 4. Clipboard Content

Supported content types:

- Text.
- Images.

Image handling:

- Support PNG, JPG, and JPEG.
- Convert WebP to PNG before saving.
- Store images locally in the app data directory.
- Show 96x96 thumbnails in the list.
- Show larger preview in the detail area.
- Images support drag export.
- Text and images both support one-click copy.

Unsupported in MVP:

- OCR image search.
- Image editing.
- Cloud upload.

## 5. History Retention

User-configurable retention:

- Retention period: 24 hours, 7 days, or 30 days.
- Item limit: user adjustable from 100 to 2000.
- Default: 7 days and 500 items.

Cleanup behavior:

1. Delete items older than the selected retention period.
2. If normal history still exceeds the item limit, delete oldest items first.
3. Favorites are not cleaned by default.
4. A setting can make favorites participate in automatic cleanup.

## 6. Duplicate Handling

- Identical content is not inserted as a new history item.
- Existing item timestamp is updated.
- The item moves to the top of the normal history list.
- Usage count is not tracked.

## 7. Favorites

- Users can favorite and unfavorite items.
- Favorites have their own filter view.
- Default behavior: favorites never expire and do not count toward the item limit.
- Optional setting: favorites also participate in automatic cleanup.
- In the Favorites view, sorting is by favorite time descending.

## 8. Search and Filters

History panel supports:

- Full-text search for text items.
- Unified list for text and images.
- Filters: All, Favorites, Images, Text, App source.
- Images are searchable only by metadata/filter in MVP, not OCR.

## 9. Source App

- Record source app name.
- Record source app icon where available.
- Allow filtering by source app.
- Do not record source window title or browser page title in MVP.
- Do not support excluded apps in MVP.

## 10. Sensitive Content

MVP behavior:

- Record all supported clipboard content.
- No automatic sensitive content detection.
- No excluded app list.
- User can delete individual records, batch delete, clear non-favorites, or clear all.
- User can pause and resume recording.

## 11. Deletion

Supported deletion operations:

- Single-item delete with a small delete icon.
- Single-item delete has no confirmation.
- Single-item delete provides a 5-second undo.
- Multi-select batch delete.
- Batch delete requires confirmation.
- Clear non-favorite history.
- Clear all history.
- Clear operations require confirmation.

## 12. Keyboard Behavior

MVP keyboard support:

- `Option + C`: open history panel.
- Type to search.
- Up/down arrows: change selection.
- Enter: copy selected item.
- Escape: close panel.
- Space: preview selected item.
- Delete: delete current item.

Advanced keyboard multi-select can come later.

## 13. Settings

MVP settings:

- Retention period.
- Item limit.
- Global shortcut.
- Close panel after copy.
- Launch at login.
- Pause/resume recording.
- Favorites participate in cleanup.
- Clear history actions.

## 14. First Launch

Show a short first-launch guide:

- Explain that history is saved locally.
- Show or configure the default `Option + C` shortcut.
- Let user choose retention period and item limit.

The user chose to request possible permissions during first launch without extra explanatory copy beyond system prompts.

## 15. Notifications

Support system notifications for:

- Copy success.
- Oversized content not recorded.
- Batch operation completed.

Do not notify every time new clipboard content is recorded.

## 16. Pause State

When recording is paused:

- Menu bar icon shows paused state.
- History panel shows paused state.
- Existing history remains searchable, copyable, deletable, and draggable.

## 17. Storage

- Store all data locally.
- No account.
- No cloud sync.
- No additional app-level encryption in MVP.
- Recommended storage:
  - SQLite for item metadata and text content.
  - Local app support directory for image files and thumbnails.

## 18. Size Limits

- Empty text is not recorded.
- Text larger than 1 MB is not recorded.
- Images larger than 20 MB are not recorded.
- Oversized content triggers a lightweight notification.

## 19. Completion Definition For MVP

The MVP is complete when:

- Menu bar app can run locally.
- `Option + C` opens the history panel.
- Text and supported images are recorded.
- Duplicate content is merged.
- Text search works.
- Filters work.
- Selected text/image can be copied back to the system clipboard.
- Images can be dragged from the history panel.
- Favorites work.
- Retention and limit cleanup work.
- Pause/resume works.
- Single and batch deletion work.
- Settings persist.
- Core logic has unit tests.

UI automation tests are not required for MVP.
