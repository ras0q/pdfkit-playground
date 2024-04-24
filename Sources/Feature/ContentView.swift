import PDFKit
import SwiftUI

public struct ContentView: View {
    public init() {}

    public var body: some View {
        PDFKitView(path: "1706.03762")
    }
}

struct PDFKitView: UIViewRepresentable {
    private let url: URL
    private let pdfView: PDFView

    init(path: String) {
        url = Bundle.module.url(
            forResource: path,
            withExtension: "pdf"
        )!

        pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        pdfView.displaysPageBreaks = false
    }

    func makeUIView(context: Context) -> some UIView {
        self.pdfView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

#Preview {
    PDFKitView(path: "1706.03762")
}
