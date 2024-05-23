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
            pdfView.document = document

            // MARK: workaround to display PKToolPicker
            // When annotating a PDF file, the PDFDocumentView becomes the first responder.
            recursiveSubviews(root: pdfView)
                .filter { "\(type(of: $0))" == "PDFDocumentView" }
                .forEach { context.coordinator.toolPicker.setVisible(true, forFirstResponder: $0) }
        }
    }

    func makeCoordinator() -> CanvasPDFCoordinator {
        Coordinator()
    }

    private func recursiveSubviews(root: UIView) -> [UIView] {
        root.subviews + root.subviews.flatMap { recursiveSubviews(root: $0) }
    }
}

class CanvasPDFCoordinator: NSObject {
    var toolPicker = PKToolPicker()
}

extension CanvasPDFCoordinator: PDFPageOverlayViewProvider {
    func pdfView(_ pdfView: PDFView, overlayViewFor page: PDFPage) -> UIView? {
        guard let pdfView = (pdfView as? CanvasPDFView) else {
            return nil
        }

        let canvasView = pdfView.pageToViewMapping[page] ?? {
            let canvasView = PKCanvasView(frame: .zero)
            canvasView.delegate = pdfView
            canvasView.drawingPolicy = .pencilOnly
            canvasView.backgroundColor = .clear
            canvasView.isOpaque = true
            canvasView.clipsToBounds = false

            pdfView.addGestureRecognizer(canvasView.drawingGestureRecognizer)
            pdfView.pageToViewMapping[page] = canvasView
            toolPicker.addObserver(canvasView)

            return canvasView
        }()

        return canvasView
    }
}

extension CanvasPDFCoordinator: PDFViewDelegate {}

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

extension CanvasPDFView: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard
            let page = pageToViewMapping.first(where: { $0.value == canvasView })?.key,
            let newStroke = canvasView.drawing.strokes.last
        else {
            return
        }
        print("writing to \(page.label!), strokes: \(canvasView.drawing.strokes.count)")

        let newDrawing = PKDrawing(strokes: [newStroke])
        let newAnnotation = CanvasPDFAnnotation(pkDrawing: newDrawing, bounds: page.bounds(for: .mediaBox))
        page.addAnnotation(newAnnotation)

        guard
            let data = document?.dataRepresentation(),
            let documentURL = document?.documentURL
        else {
            return
        }

//        try? data.write(to: documentURL)
        print("wrote!", data, documentURL)
    }
}

class CanvasPDFAnnotation: PDFAnnotation {
    let pkDrawing: PKDrawing

    init(pkDrawing: PKDrawing, bounds: CGRect) {
        self.pkDrawing = pkDrawing
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // FIXME: This is called more than necessary.
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        UIGraphicsPushContext(context)
        context.saveGState()

        // MARK: Y-flip (M' = Scale * Transform * M)
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1.0, y: -1.0)
        print("bounds", pkDrawing.bounds)

        // MARK: Using smaller `scale` reduces resolution.
        let image = pkDrawing.image(from: pkDrawing.bounds, scale: 2.0)
        image.draw(in: pkDrawing.bounds)

        context.restoreGState()
        UIGraphicsPopContext()
    }
}
