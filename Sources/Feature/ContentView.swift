import SwiftUI

public struct ContentView: View {
    public init() {}

    public var body: some View {
        ZStack {
            PDFKitView(path: "1706.03762")
        }
    }
}

#Preview {
    ContentView()
}
