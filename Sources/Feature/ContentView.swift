import SwiftUI

public struct ContentView: View {
    @State private var isImporterPresented: Bool = true
    @State private var pdfURL: URL = Bundle.module.url(
        forResource: "sample",
        withExtension: "pdf"
    )!

    public init() {}

    public var body: some View {
        ZStack(alignment: .topLeading) {
            PDFKitView(url: $pdfURL)
            Button("Open") {
                isImporterPresented = true
            }
            .buttonStyle(.bordered)
        }
            .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.pdf]) { result in
                switch result {
                case let .success(url):
                    guard url.startAccessingSecurityScopedResource() else { return }
                    pdfURL = url
                case let .failure(error):
                    print(error)
                }
            }
    }
}

#Preview {
    ContentView()
}
