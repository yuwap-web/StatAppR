# StatAppR SwiftUI実装 - Xcode統合ガイド

このドキュメントは、提供されたSwiftUI実装をXcodeプロジェクトに統合するためのステップバイステップガイドです。

---

## 📁 ファイル構成

```
StatAppR/
├── SwiftUI_Implementation/
│   ├── Models.swift              # データモデル（DataType, RecipeInfo など）
│   ├── ContentView.swift         # メインUI（左パネル + メインエリア）
│   ├── CSVManager.swift          # CSV解析・検証
│   ├── RecipeRunner.swift        # R レシピ実行
│   └── INTEGRATION_GUIDE.md       # このファイル
│
├── Sample_Data/
│   ├── 1_BasicStats_*.csv        # 基本統計サンプル
│   ├── 2_GroupComparison_*.csv   # グループ比較サンプル
│   ├── 3_Regression_*.csv        # 回帰分析サンプル
│   ├── 4_TimeSeries_*.csv        # 時系列データサンプル
│   ├── 5_Survival_*.csv          # 生存分析サンプル
│   ├── 6_CausalInference_*.csv   # 因果推論サンプル
│   ├── 7_DimensionReduction_*.csv # 次元削減サンプル
│   └── CSV_FORMAT_GUIDE.md       # CSVフォーマット説明
│
└── Engine/
    └── recipes/                   # 既存のRレシピ（30個）
```

---

## 🚀 統合手順

### ステップ1: Xcodeプロジェクトの作成

```bash
# 新規macOSプロジェクトを作成（SwiftUI）
# Xcode > File > New > Project
# - Platform: macOS
# - Type: App
# - Interface: SwiftUI
# - Project name: StatAppR
```

### ステップ2: Swiftファイルの追加

1. **Xcodeで以下のフォルダ構造を作成**:
   ```
   Xcode Project/
   ├── Models/
   │   └── Models.swift
   ├── Views/
   │   ├── ContentView.swift
   │   ├── CSVManager.swift
   │   └── RecipeRunner.swift
   └── Resources/
       └── SampleData/
   ```

2. **ファイルをXcodeにドラッグ&ドロップ**:
   - `Models.swift` → Models グループ
   - `ContentView.swift` → Views グループ
   - `CSVManager.swift` → Views グループ
   - `RecipeRunner.swift` → Views グループ

3. **Xcode Target設定確認**:
   - File Inspector で各ファイルの「Target Membership」にチェック ✓

### ステップ3: サンプルCSVファイルの追加

1. **Finder で `Sample_Data` フォルダを確認**:
   ```bash
   ls -la /Users/uts/StatAppR/Sample_Data/
   # 7つのCSVファイルが表示される
   ```

2. **Xcode で Resources フォルダに追加**:
   - File > Add Files to "StatAppR"...
   - `/Users/uts/StatAppR/Sample_Data/` を選択
   - ✓ Copy items if needed
   - ✓ Create folder references (重要)

3. **Bundle Resources確認**:
   - Target > Build Phases > Copy Bundle Resources
   - すべてのCSVが含まれていることを確認

### ステップ4: App Entry Point の更新

**StatAppRApp.swift** に以下を記述:

```swift
import SwiftUI

@main
struct StatAppRApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizabilityEnvelope(.automatic)
    }
}
```

### ステップ5: R 環境検出の設定

**Xcode Capabilities** で以下を有効化:
1. Signing & Capabilities
2. "+ Capability" > "Hardened Runtime"
3. "Disable Executable Space Protection" にチェック（Rスクリプト実行のため）

### ステップ6: Info.plist の設定

`Info.plist` に以下を追加:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Rスクリプト実行のため</string>

<key>NSBonjourServiceTypes</key>
<array>
    <string>_r-exec._tcp</string>
</array>
```

---

## 🔧 カスタマイズポイント

### 1. R スクリプトパスの設定

`RecipeRunner.swift` の以下の行を環境に合わせて更新:

```swift
let rScriptPath = "/usr/bin/Rscript"  // Rのパス
let recipesDirectory = "/Users/uts/StatAppR/Engine/recipes"  // レシピディレクトリ
```

**R のパスを確認する方法**:
```bash
which Rscript
# または
/usr/local/bin/Rscript --version
```

### 2. ウィンドウサイズの初期設定

`ContentView.swift` で以下を追加:

```swift
.frame(minWidth: 1000, minHeight: 700)
.defaultSize(width: 1200, height: 800)
```

### 3. ダークモード対応

すべての色指定は `Color(.controlBackgroundColor)` などのシステムカラーを使用（自動適用）

### 4. ローカライゼーション

日本語テキストは `Localizable.strings` に移行推奨:

```swift
// Before
Text("基本統計")

// After
Text(NSLocalizedString("basic_stats", comment: ""))
```

---

## 🧪 テストとデバッグ

### Build & Run

```bash
# Xcode内から実行
Cmd + R

# またはコマンドラインから
xcodebuild -scheme StatAppR
```

### よくある問題と解決方法

**問題 1: R が見つからない**
```
Error: R executable not found at /usr/bin/Rscript
```

**解決**:
```bash
# Rをインストール
brew install r

# パスを確認
which Rscript

# RecipeRunner.swift で正しいパスに更新
```

**問題 2: CSV ファイルが見つからない**
```
Error: Sample CSV not found in Bundle
```

**解決**:
1. Xcode > Target > Build Phases > Copy Bundle Resources を確認
2. すべてのCSVが含まれているか確認
3. Files per Configuration で `Copy items` にチェック

**問題 3: R スクリプト実行エラー**
```
Process exited with non-zero status
```

**解決**:
1. Capabilities > Hardened Runtime で実行権限を確認
2. `RecipeRunner.swift` の R コマンドを検証:
   ```bash
   /usr/bin/Rscript -e "print(R.version)"
   ```

---

## 📦 ビルド & リリース

### macOS App (.app) ビルド

```bash
# Archive を作成
xcodebuild -scheme StatAppR -archivePath ~/Desktop/StatAppR.xcarchive -configuration Release archive

# App を抽出
cd ~/Desktop/StatAppR.xcarchive/Products/Applications
cp -r StatAppR.app ~/Desktop/
```

### DMG インストーラー作成

```bash
# create-dmg をインストール
brew install create-dmg

# DMG を作成
create-dmg \
  --volname "StatAppR Installer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon StatAppR.app 175 190 \
  StatAppR.dmg \
  ~/Desktop/StatAppR.app
```

---

## 🔍 機能の詳細説明

### ContentView.swift の構成

```
ContentView
├── HStack (Main Layout)
│   ├── VStack (Left Sidebar)
│   │   ├── Welcome Section
│   │   ├── Step-by-Step Guide
│   │   ├── Data Type Selection (7 types)
│   │   └── Action Buttons (CSVLoad, PackageManager)
│   │
│   └── ZStack (Main Content Area)
│       ├── WelcomeView (初期表示)
│       ├── RecipeSelectionView (タイプ選択後)
│       └── RecipeExecutionView (レシピ実行)
```

### モジュール別機能

**Models.swift**:
- `DataType` enum: 7つのデータ分析タイプ
- `RecipeInfo`: レシピの詳細情報
- `RPackage`: Rパッケージ管理
- `CSVColumn`: CSV列の情報

**ContentView.swift**:
- `DataTypeButton`: データタイプ選択ボタン
- `RecipeCardView`: レシピ表示カード
- `PackageManagerView`: パッケージ管理UI
- `RecipeExecutionView`: 分析実行インターフェース

**CSVManager.swift**:
- `parseCSV()`: CSVファイル解析
- `detectColumnTypes()`: 列の型自動検出
- `validateCSV()`: データ検証

**RecipeRunner.swift**:
- `executeRecipe()`: R レシピ実行
- `buildRCommand()`: R コマンド構築
- `parseRecipeOutput()`: 結果JSON解析

---

## 💡 拡張機能の追加例

### 新しいデータタイプを追加する場合

1. **Models.swift** で `DataType` enum に追加:
   ```swift
   case newDataType = "新しいタイプ"
   ```

2. `recommendedRecipes` に新しいレシピ追加:
   ```swift
   case .newDataType:
       return [
           RecipeInfo(...),
           RecipeInfo(...)
       ]
   ```

3. `sampleFilename` に対応するサンプルCSVを追加

### 新しいレシピを追加する場合

1. **Engine/recipes/** に `.R` ファイルを作成
2. **Models.swift** の `recommendedRecipes` に追加
3. R ファイルの出力フォーマットを統一（JSON形式）

---

## 📋 チェックリスト

デプロイ前の確認:

- [ ] R 環境が正しく検出される
- [ ] すべてのサンプルCSVが Bundle に含まれている
- [ ] 少なくとも1つのレシピが正常に実行される
- [ ] ダークモード/ライトモードで表示確認
- [ ] CSVインポート・分析実行のフロー全体をテスト
- [ ] エラーメッセージが日本語で表示される
- [ ] 大きなCSVファイル（1000行以上）での動作確認
- [ ] macOS 11.0 以降での動作確認
- [ ] 他のユーザーアカウントでも動作確認

---

## 📚 参考リソース

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Process in Swift](https://developer.apple.com/documentation/foundation/process)
- [File Management](https://developer.apple.com/documentation/foundation/filemanager)
- [Codable Protocol](https://developer.apple.com/documentation/foundation/codable)

---

**最終更新**: 2026-03-06
**バージョン**: 1.0
**対応環境**: macOS 11.0+, Xcode 13.0+
