<img src="ScreenSeal/Resources/Assets.xcassets/icon.appiconset/icon_256x256.png" width="128" alt="ScreenSeal Icon">

# ScreenSeal

A macOS menu bar app for hiding sensitive information on screen with mosaic overlays.

Place ScreenSeal's mosaic windows over passwords, personal data, or other sensitive content during screen recordings and screenshots. The mosaic window itself is invisible to screenshots and screen sharing — only the mosaic effect is captured.

[日本語版 README はこちら](README.ja.md)

## Features

- **Real-time Mosaic** - Captures and pixelates the screen content behind the window in real time
- **3 Filter Types** - Pixellate / Gaussian Blur / Crystallize
- **Intensity Control** - Adjust via right-click menu slider or scroll wheel
- **Multiple Windows** - Place multiple mosaic regions simultaneously
- **Menu Bar Management** - List all windows, toggle visibility
- **Multi-Display Support** - Works across multiple monitors
- **Layout Presets** - Save and instantly recall window arrangements (multiple presets supported)
- **Persistent Settings** - Mosaic type and intensity are preserved across app restarts

## Requirements

- macOS 13.0 (Ventura) or later
- Screen Recording permission (a system dialog will appear on first launch)

## Installation

Download the latest `ScreenSeal.zip` from the [Releases](https://github.com/nyanko3141592/ScreenSeal/releases) page, extract it, and move `ScreenSeal.app` to your Applications folder.

## Usage

1. Launch the app — an icon appears in the menu bar
2. Click **New Mosaic Window** from the menu to create a mosaic window
3. Drag the window to cover the area you want to hide; drag the edges to resize
4. **Right-click** to open the context menu and change the filter type or intensity
5. Use the **scroll wheel** to quickly adjust intensity
6. Toggle window visibility from the menu bar

## Build

```bash
xcodebuild -project ScreenSeal.xcodeproj -scheme ScreenSeal -configuration Release build
```

## Tech Stack

- Swift / SwiftUI / AppKit
- ScreenCaptureKit (screen capture)
- Core Image (mosaic filter processing)
- Metal (GPU acceleration)

## License

MIT
