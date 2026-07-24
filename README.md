# subMission

A native macOS client for Transmission, the BitTorrent daemon.

<img width="627" height="632" alt="image" src="https://github.com/user-attachments/assets/22141936-429c-4d45-80fc-29dc119413c8" />


## Why

Transmission's web UI is sluggish over the network and lacks native keyboard shortcuts, drag-and-drop, and file-type associations. Existing remote GUI clients are Electron bloat or abandoned. subMission is a zero-dependency AppKit app that talks RPC directly to any Transmission daemon.

## Features

- Connects to any Transmission RPC endpoint (local or remote)
- Add torrents via `.torrent` file, magnet link, or drag-and-drop
- Filter by status, tracker, or download directory
- Torrent details: files, peers, trackers, transfer stats
- Start, stop, verify, remove, set location, adjust priorities
- Keyboard-driven — full menu bar with standard shortcuts
- Dark/light mode with adaptive icon
- Sandboxed, network-only — no local filesystem access beyond user-selected files
- Zero external dependencies — pure Swift + AppKit

## Install

### Homebrew (recommended)

```bash
brew tap rayone/tap
brew trust rayone/tap
brew install --cask submission
```

### Manual

1. Download `subMission.dmg` from [Releases](https://github.com/rayone/subMission/releases)
2. Open the DMG and drag `subMission.app` to `/Applications`
3. Run: `xattr -cr /Applications/subMission.app`

### Build from source

```bash
git clone https://github.com/rayone/subMission.git && cd subMission
bash build.sh release
open subMission.app
```

## Security

subMission is **unsigned** (ad-hoc codesigned only). Apple's Gatekeeper will block it on first launch because there is no $99/year Developer ID certificate. This is a free, open-source project with no revenue.

**To open the app after downloading:**

1. **Terminal (fastest):** `xattr -cr /Applications/subMission.app`
2. **System Settings:** System Settings → Privacy & Security → scroll down → click "Open Anyway"
3. **Right-click:** Right-click the app → Open → click "Open" in the dialog

Homebrew installs handle this automatically via `postflight`.

## Build from source

**Requirements:** macOS 13+ with Command Line Tools (`xcode-select --install`). No Xcode.app needed.

**Commands:**

```bash
bash build.sh release    # compile + assemble .app
bash build.sh dmg        # compile + assemble + create .dmg
bash build.sh clean      # remove all build artifacts
```

**What `build.sh` does:**
1. `swift build -c release` — compiles both targets (TransmissionRPC library + subMission app)
2. Generates `.icns` icons from source PNGs (if present on your machine)
3. Assembles the `.app` bundle with Info.plist, binary, icons
4. Strips debug symbols from the binary
5. Ad-hoc codesigns with sandbox entitlements

## Project structure

```
Package.swift            # SPM manifest — two targets, zero deps
build.sh                 # build + bundle + sign + DMG
Sources/
  TransmissionRPC/       # Pure Swift RPC client library
  subMission/            # AppKit UI (controllers, views, windows)
Resources/
  Info.plist             # Bundle metadata, file associations
  subMission.entitlements
```

## Requirements

- macOS 13 (Ventura) or later
- A running Transmission daemon with RPC enabled

## License

MIT
