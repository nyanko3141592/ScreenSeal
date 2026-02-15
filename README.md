<img src="ScreenSeal/Resources/Assets.xcassets/icon.appiconset/icon_256x256.png" width="128" alt="ScreenSeal Icon">

# ScreenSeal

画面上の機密情報をモザイクで隠すための macOS メニューバーアプリ。

画面収録やスクリーンショット撮影時に、ScreenSeal のモザイクウィンドウを配置することで、パスワードや個人情報などを安全に隠せます。モザイクウィンドウ自体はスクリーンショットや画面共有に映らず、モザイク効果のみが反映されます。

## Features

- **リアルタイムモザイク** - 背面の画面内容をリアルタイムにキャプチャしてモザイク処理
- **3種類のフィルター** - ピクセル化 / ガウスぼかし / クリスタライズ
- **強度調整** - 右クリックメニューのスライダーまたはスクロールホイールで調整
- **複数ウィンドウ** - 同時に複数のモザイク領域を配置可能
- **メニューバー管理** - ウィンドウの一覧表示、表示/非表示の切り替え
- **マルチディスプレイ対応** - 複数モニタ環境でも動作
- **画面収録から除外** - モザイクウィンドウ自体は画面キャプチャに映らない
- **設定の永続化** - モザイクタイプと強度はアプリ終了後も保持

## Requirements

- macOS 13.0 (Ventura) 以降
- Screen Recording 権限（初回起動時にシステムダイアログが表示されます）

## Installation

[Releases](https://github.com/nyanko3141592/mozaicWindow/releases) ページから最新の `ScreenSeal.zip` をダウンロードして解凍し、`ScreenSeal.app` を Applications フォルダに移動してください。

## Usage

1. アプリを起動するとメニューバーにアイコンが表示されます
2. メニューから **New Mosaic Window** をクリックしてモザイクウィンドウを作成
3. ウィンドウをドラッグして隠したい箇所に配置、端をドラッグしてリサイズ
4. **右クリック**でコンテキストメニューを開き、フィルタータイプや強度を変更
5. **スクロールホイール**でも強度を素早く調整可能
6. メニューバーからウィンドウの表示/非表示を切り替え

## Build

```bash
xcodebuild -project ScreenSeal.xcodeproj -scheme ScreenSeal -configuration Release build
```

## Tech Stack

- Swift / SwiftUI / AppKit
- ScreenCaptureKit (画面キャプチャ)
- Core Image (モザイクフィルター処理)
- Metal (GPU アクセラレーション)

## License

MIT
