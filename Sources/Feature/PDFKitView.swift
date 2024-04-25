import PencilKit
import PDFKit
import SwiftUI

struct PDFKitView: UIViewRepresentable {
    private let url: URL

    init(path: String) {
        url = Bundle.module.url(
            forResource: path,
            withExtension: "pdf"
        )!
    }

    func makeUIView(context: Context) -> UIView {
        let rootView = UIView()

        let pdfView = CanvasPDFView()
        pdfView.autoScales = true
        pdfView.displaysPageBreaks = true
        pdfView.delegate = context.coordinator
        pdfView.pageOverlayViewProvider = context.coordinator

        let document = PDFDocument(url: url)
        document?.delegate = context.coordinator
        pdfView.document = document

        rootView.addSubview(pdfView)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: rootView.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
            pdfView.leftAnchor.constraint(equalTo: rootView.leftAnchor),
            pdfView.rightAnchor.constraint(equalTo: rootView.rightAnchor)
        ])


        // MARK: workaround to display PKToolPicker
        let emptyCanvasView = PKCanvasView()
        emptyCanvasView.isHidden = true
        pdfView.toolPicker.addObserver(emptyCanvasView)
        pdfView.toolPicker.setVisible(true, forFirstResponder: emptyCanvasView)
        emptyCanvasView.becomeFirstResponder()

        rootView.addSubview(emptyCanvasView)

        return rootView
    }

    func updateUIView(_ view: UIView, context: Context) {}

    func makeCoordinator() -> CanvasPDFCoordinator {
        Coordinator()
    }
}

class CanvasPDFCoordinator: NSObject {}

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
