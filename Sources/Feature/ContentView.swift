import PDFKit
import SwiftUI

public struct ContentView: View {
    public init() {}

    public var body: some View {
        PDFKitView(path: "1706.03762")
    }
}

struct PDFKitView: UIViewRepresentable {
    private var url: URL

    private var pdfView: PDFView = {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displaysPageBreaks = false
        return pdfView
    }()

    init(path: String) {
        self.url = Bundle.module.url(forResource: path, withExtension: "pdf")!
        pdfView.document = PDFDocument(url: url)
    }

    func makeUIView(context: Context) -> some UIView {
        self.pdfView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

#Preview {
    PDFKitView(path: "1706.03762")
}
