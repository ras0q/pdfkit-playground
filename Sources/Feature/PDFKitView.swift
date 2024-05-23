import PencilKit
import PDFKit
import SwiftUI

struct PDFKitView: UIViewRepresentable {
    @Binding private var url: URL

    init(url: Binding<URL>) {
        _url = url
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = CanvasPDFView()
        pdfView.autoScales = true
        pdfView.displaysPageBreaks = true
        pdfView.delegate = context.coordinator
        pdfView.pageOverlayViewProvider = context.coordinator

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        Task {
            let document = PDFDocument(url: url)
            document?.delegate = context.coordinator
            pdfView.document = document

            // MARK: workaround to display PKToolPicker
            // When annotating a PDF file, the PDFDocumentView becomes the first responder.
            pdfView.recursiveSubviews
                .filter { "\(type(of: $0))" == "PDFDocumentView" }
                .forEach { context.coordinator.toolPicker.setVisible(true, forFirstResponder: $0) }
        }
    }

    func makeCoordinator() -> CanvasPDFCoordinator {
        Coordinator()
    }
}

class CanvasPDFCoordinator: NSObject {
    var toolPicker = PKToolPicker()
}

extension CanvasPDFCoordinator: PDFPageOverlayViewProvider {
    func pdfView(_ pdfView: PDFView, overlayViewFor page: PDFPage) -> UIView? {
        guard 
            let pdfView = (pdfView as? CanvasPDFView),
            let page = (page as? CanvasPDFPage)
        else {
            return nil
        }

        let canvasView = pdfView.pageToViewMapping[page] ?? {
            let canvasView = PKCanvasView(frame: .zero)
            canvasView.drawingPolicy = .pencilOnly
            canvasView.backgroundColor = .clear
            canvasView.isOpaque = true
            canvasView.clipsToBounds = false

            pdfView.addGestureRecognizer(canvasView.drawingGestureRecognizer)
            pdfView.pageToViewMapping[page] = canvasView
            toolPicker.addObserver(canvasView)

            return canvasView
        }()

        if let drawing = page.drawing {
            canvasView.drawing = drawing
        }

        return canvasView
    }

    func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage) {
        guard 
            let overlayView = (overlayView as? PKCanvasView),
            let page = (page as? CanvasPDFPage)
        else {
            return
        }

        page.drawing = overlayView.drawing
    }
}

extension CanvasPDFCoordinator: PDFViewDelegate {}

extension CanvasPDFCoordinator: PDFDocumentDelegate {
    func classForPage() -> AnyClass {
        CanvasPDFPage.self
    }
}

extension UIView {
    var recursiveSubviews: [UIView] {
        subviews + subviews.flatMap { $0.recursiveSubviews }
    }
}

class CanvasPDFView: PDFView {
    var pageToViewMapping = [PDFPage: PKCanvasView]()

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitPage = page(for: point, nearest: true) {
            pageToViewMapping.forEach { (page, canvasView) in
                canvasView.drawingGestureRecognizer.isEnabled = page == hitPage
            }
        }
        return super.hitTest(point, with: event)
    }
}

class CanvasPDFPage: PDFPage {
    var drawing: PKDrawing? = nil
}
