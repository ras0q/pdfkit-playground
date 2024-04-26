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

        let document = PDFDocument(url: url)
        document?.delegate = context.coordinator
        pdfView.document = document

        // MARK: workaround to display PKToolPicker
        let emptyCanvasView = PKCanvasView()
        context.coordinator.emptyCanvasView = emptyCanvasView
        emptyCanvasView.isHidden = true
        pdfView.toolPicker.addObserver(emptyCanvasView)
        pdfView.toolPicker.setVisible(true, forFirstResponder: emptyCanvasView)
        emptyCanvasView.becomeFirstResponder()

        pdfView.addSubview(emptyCanvasView)

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        Task {
            guard let emptyCanvasView = context.coordinator.emptyCanvasView else { return }
            let document = PDFDocument(url: url)
            document?.delegate = context.coordinator
            pdfView.document = document
            emptyCanvasView.becomeFirstResponder()
        }
    }

    func makeCoordinator() -> CanvasPDFCoordinator {
        Coordinator()
    }
}

class CanvasPDFCoordinator: NSObject {
    var emptyCanvasView: PKCanvasView?
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
            canvasView.tool = PKInkingTool(.pen, color: .systemRed, width: 5)

            pdfView.addGestureRecognizer(canvasView.drawingGestureRecognizer)
            pdfView.pageToViewMapping[page] = canvasView
            pdfView.toolPicker.addObserver(canvasView)

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

        page.drawing  = overlayView.drawing

        if
            let document = pdfView.document,
            let data = document.dataRepresentation(),
            let documentURL = document.documentURL
        {
            try? data.write(to: documentURL)
        }
    }
}

extension CanvasPDFCoordinator: PDFViewDelegate {}

extension CanvasPDFCoordinator: PDFDocumentDelegate {
    func classForPage() -> AnyClass {
        CanvasPDFPage.self
    }
}

class CanvasPDFView: PDFView {
    var pageToViewMapping = [PDFPage: PKCanvasView]()
    var toolPicker = PKToolPicker()

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
