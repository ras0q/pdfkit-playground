import PencilKit
import PDFKit
import SwiftUI

struct PDFKitView: UIViewRepresentable {
    private let url: URL
    private let pdfView: PDFView = {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displaysPageBreaks = false
        return pdfView
    }()

    init(path: String) {
        url = Bundle.module.url(
            forResource: path,
            withExtension: "pdf"
        )!
        pdfView.document = PDFDocument(url: url)

        let gesture = PencilRecognizer()
        pdfView.addGestureRecognizer(gesture)
    }

    func makeUIView(context: Context) -> some UIView {
        pdfView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

class PencilRecognizer: UIGestureRecognizer {
    var pdfView: PDFView {
        view as! PDFView
    }
    var path: UIBezierPath?
    var currentPage: PDFPage?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard
            touches.first?.type == .pencil,
            event.allTouches?.count == 1,
            let location = touches.first?.location(in: pdfView),
            let page = pdfView.page(for: location, nearest: true)
        else {
            state = .failed
            return
        }

        state = .began
        currentPage = page

        let convertedPoint = pdfView.convert(location, to: page) // TODO: correct?
        let newPath = UIBezierPath()
        newPath.move(to: convertedPoint)
        path = newPath
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard
            let location = touches.first?.location(in: pdfView),
            let page = currentPage,
            let path
        else {
            state = .failed
            return
        }

        state = .changed

        let convertedPoint = pdfView.convert(location, to: page)
        path.addLine(to: convertedPoint)
        path.move(to: convertedPoint)

        let annotation = PDFAnnotation(
            bounds: page.bounds(for: pdfView.displayBox),
            forType: .ink,
            withProperties: nil
        )
        annotation.color = .red
        annotation.add(path)
        page.addAnnotation(annotation)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        guard
            let location = touches.first?.location(in: pdfView),
            let page = currentPage,
            let path
        else {
            state = .failed
            return
        }

        state = .ended

        let convertedPoint = pdfView.convert(location, to: page)
        path.addLine(to: convertedPoint)
        path.move(to: convertedPoint)

        let annotation = PDFAnnotation(
            bounds: page.bounds(for: pdfView.displayBox),
            forType: .ink,
            withProperties: nil
        )
        annotation.color = .orange
        annotation.add(path)
        page.addAnnotation(annotation)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
}
