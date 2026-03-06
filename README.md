# Okaerii 🍵

> Your personal ambient soundscape companion. Create focus, relaxation, or sleep environments right from your menu bar.

<p align="center">
  <a href="https://github.com/ibidathoillah/Okaerii/releases/latest">
    <img src="https://img.shields.io/github/v/release/ibidathoillah/Okaerii?style=for-the-badge&color=blue&label=Click%20to%20download" alt="Latest Release">
  </a>
  &nbsp;
  <a href="https://github.com/ibidathoillah/Okaerii/releases/download/v1.0.0/Okaerii.dmg">
    <img src="https://img.shields.io/badge/Download-macOS-success?style=for-the-badge&logo=apple" alt="Download for macOS">
  </a>
</p>

<p align="center">
  <img src="assets/welcome-screen.png" width="600" alt="Welcome Screen" />
</p>

<p align="center">
  <img src="assets/menu-screen.png" width="45%" alt="Main Menu" />
  &nbsp;&nbsp;
  <img src="assets/create-scene-screen.png" width="45%" alt="Create Scene" />
</p>

Okaerii (おかえり) is a minimalist, open-source macOS menu bar application designed to help you stay focused, relax, or drift off to sleep with high-quality ambient audio. It lives quietly in your menu bar, ready to transform your environment with a single click.

## Features

- **High-Fidelity Audio**: We prioritize audio quality above all else. Okaerii bundles **studio-grade, uncompressed soundscapes** (Rain, Thunder, Waves, etc.) to ensure a rich, immersive experience without the digital artifacts found in streaming apps.
- **100% Offline & Private**: All high-quality assets are stored locally. No internet connection required, no buffering, no tracking, and no monthly subscriptions.
- **Menu Bar Native**: Runs entirely in the background with a lightweight system footprint. Accessible via a simple `🍵` icon.
- **Curated Scenes**: Instantly switch between handcrafted environments like "Deep Work", "Midnight Rain", and "Forest Zen".
- **Custom Mixes**: Create your own perfect atmosphere by mixing layers and adjusting individual volumes to your taste.
- **Gapless Looping**: Our custom audio engine ensures seamless, infinite playback without jarring interruptions.
- **Minimalist UI**: A clean, distraction-free interface built with SwiftUI.

## Installation

### Download Official Release

1.  Download the latest **Okaerii.dmg** from [GitHub Releases](https://github.com/ibidathoillah/Okaerii/releases/latest).
2.  Open the DMG and drag **Okaerii.app** to your **Applications** folder.

> [!IMPORTANT]
> **macOS Gatekeeper Note:** Since this is an open-source app not signed by an Apple Developer certificate, you may see a message saying "Okaerii is damaged" or "cannot be opened". To fix this, run the following command in your Terminal:
> ```bash
> xattr -cr /Applications/Okaerii.app
> ```

### From Source

You can run Okaerii directly using Swift Package Manager:

```bash
git clone https://github.com/ibidathoillah/Okaerii.git
cd Okaerii
swift run
```

### Building the App

To create a standalone `.app` and `.dmg` installer locally:

```bash
./scripts/build_installer.sh
```

### Automation (One-Click Release)

To automate the entire Build -> Commit -> Tag -> Push -> GitHub Release flow:

```bash
chmod +x scripts/release.sh
./scripts/release.sh
```

This will guide you through the versioning and release process using the `gh` CLI and our CI/CD pipeline.

## Development

Okaerii is built using:
- **Swift 5.9+**
- **SwiftUI** for the user interface
- **AppKit** for window management and menu bar integration
- **AVFoundation** for high-performance audio mixing

### Requirements
- macOS 14.0 (Sonoma) or later
- Xcode 15+ (for development)

### Xcode Setup
1. Ensure you have [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed (`brew install xcodegen`).
2. Run `xcodegen generate` in the project root.
3. Open `Okaerii.xcodeproj`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Made with 🍵 by [Ibid Athoillah](https://github.com/ibidathoillah).
