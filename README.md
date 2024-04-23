# spm-project-template

ref: https://speakerdeck.com/d_date/swift-package-centered-project-build-and-practice

`swift package init --name Feature`

XCodeを開きプロジェクトルート下にworkspaceを作成
- `File -> New -> Workspace`
- 名前は`App.xcworkspace`とかでOK

プロジェクトルートをworkspaceに追加
- `File -> Add Files to "project"`

プロジェクトルート下にprojectを作成
- `Files -> New -> Project`
- 名前は`App` (なんでもいい)
- Add to, Groupは指定しない
- 新しく開いたXCodeのウィンドウは閉じる

`App/`の下のファイルを改名する
- `App/App` → `App/iOS`
- `App/App/AppApp.swift` → `App/iOS/iOS.swift` (ついでに中身も変更)
- xcodeprojのDevelopment Assets (ビルドしてエラーが出てからで良い):
    - `App/Preview Contents` → `iOS/Preview Contents`

Finderを開き`App/App.xcodeproj`をXCode上のworkspaceにドラッグ&ドロップ

`App.xcodeproj`とSwift Packageで`App/`が二重に参照されているので`App/Package.swift`を作成して見えないようにする(HACK)
- xcodeprojに認識させると`No such module 'PackageDescription'`が出るので参照は消してXCodeからは見えないようにする

```swift
// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "iOS",
    products: [],
    targets: []
)
```

`Sources/Feature/Feature.swift`を消して`iOS/ContentView.swift`を置く
- SwiftUIを使う場合は`Package.swift`に`platform`でiOS13以上を指定
- `public`をつけて`iOS`から呼び出せるようにする

`iOS.xcodeproj`の`iOS`ターゲットに`Feature`への依存を追加
- `iOS.xcodeproj -> TARGETS -> General -> Frameworks, Libraries, and Embedded Content`
- `App/iOS/iOS.swift`に`import Feature`を追加

