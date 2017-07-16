import AppKit
import CoreGraphics


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public class CanvasView: NSView {
    public typealias Configuration = MappedAccessConfiguration
    public typealias UndoDelegate = CanvasViewUndoDelegate

    private typealias Graph = UndirectedGraph
    private typealias Vertex = Graph.Vertex
    private typealias Edge = Graph.Edge
    private typealias Path = Graph.Path


    // MARK: - Object Lifecycle

    public override init(frame: CGRect) {
        let configuration = Configuration()

        self.committedConfiguration = configuration
        self.currentConfiguration = configuration
        self.drawing = ForceDirectedDrawing(for: configuration)

        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        fatalError()
    }

    public override var acceptsFirstResponder: Bool {
        return true
    }



    // MARK: - Size

    public override var bounds: CGRect {
        didSet { self.reloadNormalizingTransform() }
    }

    public override var frame: CGRect {
        didSet { self.reloadNormalizingTransform() }
    }

    public override func setFrameSize(_ size: CGSize) {
        super.setFrameSize(size)

        self.reloadNormalizingTransform()
    }

    public override func setBoundsSize(_ size: CGSize) {
        super.setBoundsSize(size)

        self.reloadNormalizingTransform()
    }



    // MARK: - Transformation

    private var normalizingTransform: CGAffineTransform = .identity {
        didSet { self.reloadEffectiveTransform() }
    }

    private var committedUserTransform: CGAffineTransform = .identity {
        didSet { self.currentUserTransform = self.committedUserTransform }
    }

    private var currentUserTransform: CGAffineTransform = .identity {
        didSet { self.reloadEffectiveTransform() }
    }

    private var effectiveTransform: CGAffineTransform = .identity {
        didSet { self.setNeedsDisplay(NSRect.infinite) }
    }

    private func reloadNormalizingTransform() {
        let bounds = CGRect(origin: .zero, size: self.bounds.size)
        let center = bounds.center

        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.scaledBy(x: +1, y: +1)

        self.normalizingTransform = transform
    }

    private func reloadEffectiveTransform() {
        let normalizingTransform = self.normalizingTransform
        let currentUserTransform = self.currentUserTransform
        let effectiveTransform = currentUserTransform.appending(normalizingTransform)

        self.effectiveTransform = effectiveTransform
    }



    // MARK: - Drawing

    public var committedConfiguration: Configuration {
        didSet {
            if self.committedConfiguration != oldValue {
                self.delegate?.undoManager?.registerUndo(withTarget: self, handler: {
                    $0.committedConfiguration = oldValue
                })
            }

            self.currentConfiguration = self.committedConfiguration
            self.state = .idle
        }
    }

    private var currentConfiguration: Configuration {
        didSet {
            self.drawing = ForceDirectedDrawing(for: self.currentConfiguration)
        }
    }

    private var drawing: ForceDirectedDrawing {
        didSet {
            self.setNeedsDisplay(NSRect.infinite)
        }
    }



    // MARK: - Hill Climbing

    private var optimizer: Optimizer? = nil {
        didSet {
            self.delegate?.undoManager?.registerUndo(withTarget: self, handler: {
                $0.optimizer = oldValue
            })

            if let optimizer = self.optimizer {
                self.committedConfiguration = optimizer.configuration
            }
        }
    }



    // MARK: - Rendering

    public override func draw(_ rect: CGRect) {
        let context = NSGraphicsContext.current()!.cgContext

        self.drawHUD(in: context)

        context.concatenate(self.effectiveTransform)

        self.drawGraph(in: context)
    }

    private func drawGraph(in context: CGContext) {
        context.setFlatness(0.5)

        for path in self.drawing.paths {
            let arc = drawing.arc(for: path)
            let color = NSColor.black

            context.saveGState()
            context.beginPath()
            context.addPath(arc.path)
            context.setLineWidth(1)
            context.setLineCap(.round)
            context.setStrokeColor(color.cgColor)
            context.strokePath()
            context.restoreGState()
        }

        for vertex in self.drawing.vertices {
            let location = self.drawing.location(of: vertex)

            do {
                let rect = CGRect(center: location, size: CGSize(width: 8, height: 8))

                do {
                    var point = location
                    point.x += 5
                    point.y += 2
                    self.draw(vertex.name, at: point, in: context, alignment: .left)
                }

                context.saveGState()
                context.beginPath()
                context.addEllipse(in: rect)
                context.setFillColor(NSColor.black.cgColor)
                context.fillPath()
                context.restoreGState()
            }
        }
    }

    private func drawHUD(in context: CGContext) {
//        self.drawEnergy(in: context)
//        self.drawLombardiness(in: context)

        let text = self.drawing.hasFiniteEnergy ? "finite" : "infinite"

        self.draw(text, at: CGPoint(x: self.bounds.width - 5, y: 5), in: context, alignment: .right)
    }

//    private func drawEnergy(in context: CGContext) {
//        let energy = self.drawing.energy
//
//        let formatter = NumberFormatter()
//        formatter.minimumIntegerDigits = 1
//        formatter.minimumFractionDigits = 4
//        formatter.maximumFractionDigits = 4
//
//        let text = formatter.string(from: NSNumber(value: energy))!
//
//        self.draw(text, at: CGPoint(x: self.bounds.width - 5, y: 5), in: context, alignment: .right)
//    }

//    private func drawLombardiness(in context: CGContext) {
//        let lombardiness = self.drawing.lombardiness
//
//        let formatter = NumberFormatter()
//        formatter.minimumIntegerDigits = 1
//        formatter.minimumFractionDigits = 5
//        formatter.maximumFractionDigits = 5
//
//        let text = formatter.string(from: NSNumber(value: lombardiness))!
//
//        self.draw(text, at: CGPoint(x: 5, y: 5), in: context, alignment: .left)
//    }

    private func draw(_ text: String, at position: CGPoint, in context: CGContext, alignment: NSTextAlignment) {
        let attributes = [
            NSFontAttributeName: NSFont(name: "Courier", size: 16)!
        ]

        let string = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(string)
        let width = CTLineGetBoundsWithOptions(line, .useOpticalBounds).width

        switch alignment {
        case .left:
            context.textPosition.x = position.x
            context.textPosition.y = position.y
        case .center:
            context.textPosition.x = position.x - width / 2
            context.textPosition.y = position.y
        case .right:
            context.textPosition.x = position.x - width
            context.textPosition.y = position.y
        default:
            fatalError()
        }

        CTLineDraw(line, context)
    }



    // MARK: - Undo & Redo Helpers

    public weak var delegate: UndoDelegate? = nil

    private func performGroupedForUndo(_ closure: () -> Void) {
        if let manager = self.delegate?.undoManager {
            manager.beginUndoGrouping()

            closure()

            manager.endUndoGrouping()
        }
        else {
            closure()
        }
    }

    private func registerUndo(for optimizer: Optimizer) {
        self.delegate?.undoManager?.registerUndo(withTarget: self, handler: {
            optimizer.undo()

            $0.registerRedo(for: optimizer)
        })
    }

    private func registerRedo(for optimizer: Optimizer) {
        self.delegate?.undoManager?.registerUndo(withTarget: self, handler: {
            optimizer.redo()

            $0.registerUndo(for: optimizer)
        })
    }



    // MARK: - State

    private enum State {
        case idle
        case dragging(CGPoint)
        case adjustingVertex(Vertex, Bool)
        case adjustingPath(Path, Bool)
    }

    private var state: State = .idle



    // MARK: - Helpers

    private func location(of event: NSEvent) -> CGPoint {
        let point = self.convert(event.locationInWindow, from: nil)
        let converted = point.applying(self.effectiveTransform.inverted())

        return converted
    }

    private func vertex(at point: CGPoint) -> Vertex? {
        var hit: (vertex: Vertex, distance: CGFloat)? = nil

        for vertex in self.drawing.vertices {
            let location = self.drawing.location(of: vertex)
            let distance = location.distance(to: point)

            guard distance <= 10 else {
                continue
            }

            if let current = hit?.distance, current < distance {
            }
            else {
                hit = (vertex, distance)
            }
        }

        return hit?.vertex
    }

    private func path(at point: CGPoint) -> Path? {
        var hit: (path: Path, distance: CGFloat)? = nil

        for path in self.drawing.paths {
            let arc = self.drawing.arc(for: path)
            let distance = arc.distance(to: point)

            guard distance <= 10 else {
                continue
            }

            if let current = hit?.distance, current < distance {
            }
            else {
                hit = (path, distance)
            }
        }

        return hit?.path
    }

    private func configuration(with vertex: Vertex, at point: CGPoint) -> Configuration? {
        return self.currentConfiguration.with(vertex, at: point)
    }

    private func configuration(with path: Path, intersecting point: CGPoint) -> Configuration? {
        return self.currentConfiguration.with(path, intersecting: point)
    }



    // MARK: - User Adjustments

    public override func mouseDown(with event: NSEvent) {
        guard case .idle = self.state else {
            preconditionFailure()
        }

        let location = self.location(of: event)

        if let vertex = self.vertex(at: location) {
            self.state = .adjustingVertex(vertex, false)
        }
        else if let path = self.path(at: location) {
            self.state = .adjustingPath(path, false)
        }
        else {
            self.state = .dragging(location)
        }
    }

    public override func mouseDragged(with event: NSEvent) {
        let point = self.location(of: event)

        switch self.state {
        case .idle:
            break
        case .adjustingVertex(let vertex, _):
            if let configuration  = self.configuration(with: vertex, at: point) {
                self.currentConfiguration = configuration
            }

            self.state = .adjustingVertex(vertex, true)
        case .adjustingPath(let path, _):
            if let configuration = self.configuration(with: path, intersecting: point) {
                self.currentConfiguration = configuration
            }

            self.state = .adjustingPath(path, true)
        case .dragging(let start):
            let translation = CGVector(from: start, to: point)

            var transform = CGAffineTransform.identity
            transform.displace(by: translation)

            self.committedUserTransform.prepend(transform)
        }
    }

    public override func mouseUp(with event: NSEvent) {
        switch self.state {
        case .idle:
            self.state = .idle
        case .adjustingVertex(_, let changed):
            if changed {
                self.performGroupedForUndo({
                    self.optimizer = nil
                    self.committedConfiguration = self.currentConfiguration
                })
            }

            self.state = .idle
        case .adjustingPath(_, let changed):
            if changed {
                self.performGroupedForUndo({
                    self.optimizer = nil
                    self.committedConfiguration = self.currentConfiguration
                })
            }

            self.state = .idle
        case .dragging:
            self.state = .idle
        }
    }

    public override func scrollWheel(with event: NSEvent) {
        guard event.subtype == .mouseEvent else {
            return
        }

        let center = self.location(of: event)

        let dx = event.scrollingDeltaX
        let dy = event.scrollingDeltaY

        let scale = exp(0.05 * dy)
        let angle = -dx * CGAngle(degrees: 4)

        var transform = CGAffineTransform.identity
        transform.scale(by: scale)
        transform.rotate(by: angle)
        transform = transform.relative(to: center)

        self.committedUserTransform.prepend(transform)
    }



    // MARK: - Stepping

    private var rightMouseDown: Bool = false

    public override func rightMouseDown(with event: NSEvent) {
//        guard self.drawing.energy.isFinite else {
//            let error = NSError(domain: "", code: 0, userInfo: [
//                NSLocalizedDescriptionKey: "Cannot hill-climb from state with infinite energy."
//            ])
//
//            let alert = NSAlert(error: error)
//            alert.runModal()
//
//            return
//        }
//
//        self.rightMouseDown = true
//
//        self.stepContinuouslyIfRightMouseDown()

        self.step()
    }

    public override func rightMouseUp(with event: NSEvent) {
        self.rightMouseDown = false
    }

    private func stepContinuouslyIfRightMouseDown() {
        guard self.rightMouseDown else {
            return
        }

        self.step()

        let deadline = DispatchTime.now() + DispatchTimeInterval.milliseconds(100)
        DispatchQueue.main.asyncAfter(deadline: deadline, execute: {
            self.stepContinuouslyIfRightMouseDown()
        })
    }

    private func step() {
        let before = CACurrentMediaTime()

//        self.performGroupedForUndo({
//            if let optimizer = self.optimizer {
//                optimizer.step()
//
//                self.committedConfiguration = optimizer.configuration
//
//                self.registerUndo(for: optimizer)
//            }
//            else {
//                let optimizer = ConcreteHillClimber(from: self.currentConfiguration)
////                let optimizer = DerivativeBasedOptimizer(from: self.currentConfiguration)
//                optimizer.step()
//
//                self.optimizer = optimizer
//                self.committedConfiguration = optimizer.configuration
//            }
//        })

        let configuration = self.committedConfiguration
        var coordinates = VectorAccessConfiguration(for: configuration).coordinates

        var paths: [Vertex: Path] = [:]
        var traditionalForces: [Vertex: CGVector] = [:]
        var generalizedForces: [GeneralizedCoordinate: CGFloat] = [:]

        for path in self.drawing.paths {
            for vertex in path.internalVertices {
                paths[vertex] = path
            }
        }

        for vertex in self.drawing.vertices {
            traditionalForces[vertex] = self.drawing.force(actingOn: vertex)
        }


        Swift.print()

        for q_j in coordinates {
            var Q_j = 0 as CGFloat

            switch q_j {
            case .x(let vertex, _):
                for other in self.drawing.vertices {
                    let drdq: CGVector

                    if other === vertex {
                        drdq = CGVector(dx: 1, dy: 0)
                    }
                    else if let path = paths[other] {
                        let arc = self.drawing.arc(for: path)
                        let progress = configuration.progresses[other]!

                        if vertex === path.vertices.first {
                            drdq = arc.derivativeWithRespectToStartX(at: progress)
                        }
                        else if vertex === path.vertices.last {
                            drdq = arc.derivativeWithRespectToEndX(at: progress)
                        }
                        else {
                            drdq = .zero
                        }
                    }
                    else {
                        drdq = .zero
                    }

                    Q_j += traditionalForces[other]! * drdq
                }
            case .y(let vertex, _):
                for other in self.drawing.vertices {
                    let drdq: CGVector

                    if other === vertex {
                        drdq = CGVector(dx: 0, dy: 1)
                    }
                    else if let path = paths[other] {
                        let arc = self.drawing.arc(for: path)
                        let progress = configuration.progresses[other]!

                        if vertex === path.vertices.first {
                            drdq = arc.derivativeWithRespectToStartY(at: progress)
                        }
                        else if vertex === path.vertices.last {
                            drdq = arc.derivativeWithRespectToEndY(at: progress)
                        }
                        else {
                            drdq = .zero
                        }
                    }
                    else {
                        drdq = .zero
                    }

                    Q_j += traditionalForces[other]! * drdq
                }
            case .progress(let vertex, _):
                let path = paths[vertex]!
                let arc = self.drawing.arc(for: path)
                let progress = configuration.progresses[vertex]!
                let drdq = arc.derivativeWithRespectToProgress(at: progress)

                Q_j += traditionalForces[vertex]! * drdq
            case .angle(let path, _):
                for other in self.drawing.vertices {
                    let drdq: CGVector

                    if path.internalVertices.contains(other) {
                        let arc = self.drawing.arc(for: path)
                        let progress = configuration.progresses[other]!

                        drdq = arc.derivativeWithRespectToAngle(at: progress)
                    }
                    else {
                        drdq = .zero
                    }

                    Q_j += traditionalForces[other]! * drdq
                }
            }

            generalizedForces[q_j] = Q_j
        }

        Swift.print()
        Swift.print("TRADITIONAL FORCES")
        Swift.print("==================")
        for (vertex, force) in traditionalForces {
            Swift.print("\(vertex):", force)
        }

        Swift.print()
        Swift.print("GENERALIZED FORCES")
        Swift.print("==================")
        for (vertex, force) in generalizedForces {
            Swift.print("\(vertex):", force)
        }

        do {
            var scale1 = 1 as CGFloat
            var scale2 = 1 as CGFloat

            for coordinate in coordinates {
                let force = fabs(generalizedForces[coordinate]!)

                switch coordinate {
                case .x: scale1 = min(scale1, 10 / force)
                case .y: scale1 = min(scale1, 10 / force)
                case .angle: scale2 = min(scale2, CGAngle.degrees(10).radians / force)
                case .progress: scale2 = min(scale2, 0.1 / force)
                }
            }

            Swift.print("adjusting with scale =", scale1, scale2)

            for index in coordinates.indices {
                switch coordinates[index] {
                case .x, .y:
                    coordinates[index].rawValue += scale1 * generalizedForces[coordinates[index]]!
                case .angle, .progress:
                    coordinates[index].rawValue += scale2 * generalizedForces[coordinates[index]]!
                }

            }
        }

        let newConfiguration = MappedAccessConfiguration(for: configuration.paths, coordinates: coordinates)
        self.committedConfiguration = newConfiguration

        let after = CACurrentMediaTime()
        let delta = after - before

        Swift.print()
        Swift.print(String(format: "%#8.3fms", 1000 * delta))
    }



    // MARK: - Key Commands

    @IBAction public func randomize(_ sender: Any) {
        let paths = self.committedConfiguration.paths
        let builder = RandomizedConfigurationBuilder(for: paths)
        let configuration = builder.configuration

        self.performGroupedForUndo({
            self.optimizer = nil
            self.committedConfiguration = configuration
        })
    }

    @IBAction public func resetTransform(_ sender: Any) {
        self.committedUserTransform = .identity
    }

    @IBAction public func export(_ sender: Any) {
//        let window = self.window!
//        var title = window.title
//
//        for suffix in [".graphml", ".paths", ".arcs"] {
//            if let range = title.range(of: suffix), range.upperBound == title.endIndex {
//                title.removeSubrange(range)
//            }
//        }
//
//        let panel = NSSavePanel()
//        panel.nameFieldStringValue = title
//        panel.allowedFileTypes = ["svg"]
//
//        panel.beginSheetModal(for: window, completionHandler: {
//            if let url = panel.url, $0 != NSFileHandlingPanelCancelButton {
//                let data = self.drawing.svg(for: self.effectiveTransform)
//                try! data.write(to: url)
//            }
//        })
    }
}
