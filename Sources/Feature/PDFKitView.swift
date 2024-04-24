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

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displaysPageBreaks = true
        pdfView.delegate = context.coordinator
        pdfView.pageOverlayViewProvider = context.coordinator

        let document = PDFDocument(url: url)
        document?.delegate = context.coordinator
        pdfView.document = document

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {}

    func makeCoordinator() -> CanvasPDFCoordinator {
        Coordinator()
    }
}

class CanvasPDFCoordinator: UIView {
    var pageToViewMapping = [PDFPage: PKCanvasView]()
}

extension CanvasPDFCoordinator: PDFPageOverlayViewProvider {
    func pdfView(_ pdfView: PDFView, overlayViewFor page: PDFPage) -> UIView? {
        pageToViewMapping[page] ?? {
            // FIXME: 一番最後にvisibleになったページにしか書き込めない
            // FIXME: 進んで戻ると消えてる
            let canvasView = PKCanvasView(frame: page.bounds(for: pdfView.displayBox))
            canvasView.drawingPolicy = .anyInput
            canvasView.backgroundColor = .clear
            canvasView.isOpaque = true
            canvasView.clipsToBounds = false
            canvasView.becomeFirstResponder()
            pdfView.addGestureRecognizer(canvasView.drawingGestureRecognizer)

            // FIXME: 表示されない
            let picker = PKToolPicker()
            picker.setVisible(true, forFirstResponder: canvasView)
            picker.addObserver(canvasView)

            pageToViewMapping[page] = canvasView

            return canvasView
        }()
    }

    func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage) {
        // FIXME: not visibleになる際にPDFに書き込もうとしているがうまくいかない
        guard let drawing = (page as? CanvasPDFPage)?.drawing else { return }
        let annotation = CanvasPDFAnnotation(
            bounds: drawing.bounds,
            forType: .stamp,
            withProperties: nil
        )
        let codedData = try! NSKeyedArchiver.archivedData(
            withRootObject: drawing,
            requiringSecureCoding: true
        )
        annotation.setValue(
            codedData,
            forAnnotationKey: PDFAnnotationKey(rawValue: "drawingData")
        ) // TODO: what?

        page.addAnnotation(annotation)
    }
}

extension CanvasPDFCoordinator: PDFViewDelegate {}

extension CanvasPDFCoordinator: PDFDocumentDelegate {
    func classForPage() -> AnyClass {
        CanvasPDFPage.self
    }
}

class CanvasPDFPage: PDFPage {
    var drawing: PKDrawing? = nil
}

class CanvasPDFAnnotation: PDFAnnotation {
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        UIGraphicsPushContext(context) // TODO: what?
        context.saveGState()

        if let drawing = (page as? CanvasPDFPage)?.drawing {
            let image = drawing.image(from: drawing.bounds, scale: 1)
            image.draw(in: drawing.bounds)
        }

        context.restoreGState()
        UIGraphicsPopContext()
    }
}
