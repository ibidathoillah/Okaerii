# Okaerii 🍵

Okaerii (おかえり) is a minimalist, open-source macOS menu bar application designed to help you stay focused with high-quality ambient audio.

## Features
- **Minimalist Menu Bar UI**: Runs entirely in the background, keeping your workspace clean.
- **High-Quality Audio**: A curated list of ambient scenes including "Midnight Rain" and "Deep Work".
- **Seamless Looping**: Custom audio engine for gapless, smooth audio transitions.
- **Volume Control**: Easy-to-access volume slider within the menu bar popover.

## Installation
Currently, Okaerii is available as source code. You can build it using Swift Package Manager:

```bash
swift run Okaerii --disable-sandbox
```

## How to Build with Xcode
1. Ensure you have [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed.
2. Run `xcodegen generate` in the project root.
3. Open `Okaerii.xcodeproj`.
4. Select the `Okaerii` target and press `Cmd+R`.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
