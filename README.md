# Lineshot

<img src="Assets/Lineshot.png" width="128" alt="Lineshot app icon">

A small native macOS shelf for screenshots, copied text, and a notebook that stays within reach.

Lineshot is an independent fork of [Tendedero](https://github.com/alejandrobujan/tendedero) by Alejandro Buján. It is not an official Tendedero release and is not endorsed by its author. The original interaction style and Git history are retained; this fork uses its own name and icon.

[简体中文](docs/i18n/README.zh-Hans.md) · [Changelog](CHANGELOG.md) · [Development branch](https://github.com/sophonil/lineshot/tree/feature/customizations)

## Changes from Tendedero

- **Text clippings:** enable **Hang copied text** to hang plain text alongside screenshots. Click to copy the full text, preserving whitespace and Unicode. Text capture is opt-in, skips private/transient clipboard entries, and ignores blank text or text over 1 MiB.
- **Pinned notebook:** the first card opens a small window for adding, editing, completing, and deleting tasks, plus free-form notes. Press Return to add a task. Saved tasks and notes return after relaunching.
- **Centered layout:** the notebook and clippings stay centered as a group and expand toward both edges. With no clippings, the notebook sits in the center. When the row overflows, clippings scroll while the notebook keeps the first slot.

The original screenshot gestures, glass frames, clips, and automatic hiding remain. **Take everything down** removes screenshot/text cards, leaving the notebook intact. Files in the app's own screenshot directory go to the Trash; files elsewhere are only removed from the line. The menu is disabled when there are no clippings to remove.

## Current version

**0.1.1** fixes standard editing shortcuts in the notebook: paste, copy, cut, select all, undo, and redo work in the new-task field, existing tasks, and notes. See the [changelog](CHANGELOG.md) for the first fork release and subsequent fixes.

Development happens on `feature/customizations`; `main` retains the original upstream snapshot. Binary downloads are not yet published to GitHub Releases. You can build the app from the instructions below.

## Install and data

Requires macOS 14 or later. Builds contain both Apple silicon and Intel executables.

If you have a packaged build, quit the earlier app, extract its ZIP, and drag **Lineshot.app** to Applications. Local builds are ad hoc signed unless you provide a Developer ID identity; ad hoc builds are not notarized by Apple.

Lineshot uses bundle ID `io.github.sophonil.Lineshot` and stores captures under `~/Library/Application Support/Lineshot/Screenshots`. On its first launch it copies only the saved notebook from the earlier personal Tendedero build, if present. It does not modify the original notebook or import screenshot routing, clipboard settings, or old file paths. Enable capture options again in the menu as needed. Run only one screenshot-handling app at a time.

No account, analytics, or content upload is added. Text clips are local UTF-8 files created with owner-only permissions. Tasks and notes are saved in local preferences. **Check for Updates…** opens this fork's GitHub releases page in your browser.

## Build from source

```sh
git clone https://github.com/sophonil/lineshot.git
cd lineshot
git switch feature/customizations
scripts/build-app.sh
open build/Lineshot.app
```

Requires the Swift toolchain. The internal Swift module and source directory retain the upstream `Tendedero` name to keep code comparisons straightforward. The build script can fall back to an installed macOS 26 SDK if the newer Command Line Tools SDK cannot compile SwiftUI.

```sh
swift test
swift scripts/check-strings.swift
```

For a disk image, run `scripts/make-dmg.sh`. The resulting image is not automatically notarized. For a ZIP, use `ditto -c -k --sequesterRsrc --keepParent build/Lineshot.app build/Lineshot-0.1.1.zip`.

## Credits and license

Original application: **Alejandro Buján**, [alejandrobujan/tendedero](https://github.com/alejandrobujan/tendedero). Fork additions and supplied app icon: **sophonil**.

The original copyright and [LICENSE](LICENSE) are preserved. The upstream Tendedero name and icon are not covered by its MIT source license; Lineshot uses a different name and original icon artwork. Other translated upstream documents and artwork in the Git history describe the original project, not this fork's releases.
