import Foundation


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public final class ForceDirectedOptimizer: Optimizer {
    public typealias Graph = UndirectedGraph
    public typealias Vertex = Graph.Vertex
    public typealias Edge = Graph.Edge
    public typealias Path = Graph.Path


    // MARK: - Initialization

    public init(from configuration: MappedAccessConfiguration) {
        let drawing = Drawing(for: configuration)

        precondition(drawing.energy.isFinite)

        self.configuration = configuration
    }

    public convenience init(for paths: GreedilyRealizableSequenceOfPaths) {
        let builder = RandomizedConfigurationBuilder(for: paths)
        let configuration = builder.configuration

        self.init(from: configuration)
    }



    // MARK: - Properties

    private(set) public var configuration: MappedAccessConfiguration {
        didSet {
            self.undoManager.registerUndo(withTarget: self, handler: {
                $0.configuration = oldValue
            })
        }
    }

    private var temperature: CGFloat = 1.0 {
        didSet {
            self.undoManager.registerUndo(withTarget: self, handler: {
                $0.temperature = oldValue
            })
        }
    }



    // MARK: - Helpers

    private var internalVertexToPathMap: [Vertex: Path] {
        let drawing = Drawing(for: self.configuration)

        var paths: [Vertex: Path] = [:]

        for path in drawing.paths {
            for vertex in path.internalVertices {
                paths[vertex] = path
            }
        }

        return paths
    }

    private var traditionalForces: [Vertex: CGVector] {
        let drawing = Drawing(for: self.configuration)

        var forces: [Vertex: CGVector] = [:]

        for vertex in drawing.graph.vertices {
            forces[vertex] = drawing.force(actingOn: vertex)
        }

        return forces
    }

    internal var generalizedForces: [GeneralizedCoordinate: CGFloat] {
        let drawing = Drawing(for: self.configuration)
        let coordinates = VectorAccessConfiguration(for: self.configuration).coordinates

        let traditionalForces = self.traditionalForces
        let paths = self.internalVertexToPathMap

        var forces: [GeneralizedCoordinate: CGFloat] = [:]

        for coordinate in coordinates {
            var force = 0 as CGFloat

            switch coordinate {
            case .x(let vertex, _):
                for other in drawing.graph.vertices {
                    let drdq: CGVector

                    if other === vertex {
                        drdq = CGVector(dx: 1, dy: 0)
                    }
                    else if let path = paths[other] {
                        let arc = drawing.arc(for: path)
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

                    force += traditionalForces[other]! * drdq
                }
            case .y(let vertex, _):
                for other in drawing.graph.vertices {
                    let drdq: CGVector

                    if other === vertex {
                        drdq = CGVector(dx: 0, dy: 1)
                    }
                    else if let path = paths[other] {
                        let arc = drawing.arc(for: path)
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

                    force += traditionalForces[other]! * drdq
                }
            case .progress(let vertex, _):
                let path = paths[vertex]!
                let arc = drawing.arc(for: path)
                let progress = configuration.progresses[vertex]!
                let drdq = arc.derivativeWithRespectToProgress(at: progress)

                force += traditionalForces[vertex]! * drdq
            case .angle(let path, _):
                for other in drawing.graph.vertices {
                    let drdq: CGVector

                    if path.internalVertices.contains(other) {
                        let arc = drawing.arc(for: path)
                        let progress = configuration.progresses[other]!

                        drdq = arc.derivativeWithRespectToAngle(at: progress)
                    }
                    else {
                        drdq = .zero
                    }

                    force += traditionalForces[other]! * drdq
                }
            }

            forces[coordinate] = force
        }

        return forces
    }



    // MARK: - Stepping

    public func step() {
        let configuration = self.configuration
        let drawing = Drawing(for: configuration)
        let paths = self.configuration.paths

        let coordinates = VectorAccessConfiguration(for: configuration).coordinates
        let traditionalForces = self.traditionalForces
        let generalizedForces = self.generalizedForces

//        print()
//        print("TRADITIONAL FORCES")
//        print("==================")
//        print(traditionalForces.map({ "\($0.key): \($0.value)" }).sorted().joined(separator: "\n"))

//        print()
//        print("GENERALIZED FORCES")
//        print("==================")
//        print(generalizedForces.map({ "\($0.key)  =>  \($0.value)" }).sorted().joined(separator: "\n"))

        var positionalScale: CGFloat = 1
        var angularScale: CGFloat = 1
        var progressScale: CGFloat = 1

        do {
            for coordinate in coordinates {
                let magnitude = fabs(generalizedForces[coordinate]!)

                switch coordinate {
                case .x: positionalScale = min(positionalScale, 10 / magnitude)
                case .y: positionalScale = min(positionalScale, 10 / magnitude)
                case .angle: angularScale = min(angularScale, CGAngle.degrees(10).radians / magnitude)
                case .progress: progressScale = min(progressScale, 0.1 / magnitude)
                }
            }
        }

        do {
            var scale = self.temperature

            let adjustedCoordinates = {
                return coordinates.map({ coordinate -> GeneralizedCoordinate in
                    let force = generalizedForces[coordinate]!
                    var copy = coordinate

                    switch copy {
                    case .x, .y:
                        copy.rawValue += scale * positionalScale * force
                    case .angle:
                        copy.rawValue += scale * angularScale * force
                    case .progress:
                        copy.rawValue += scale * progressScale * force
                    }

                    return copy
                })
            }

            var newConfiguration = MappedAccessConfiguration(for: paths, coordinates: adjustedCoordinates())
            var newDrawing = Drawing(for: newConfiguration)

            while !newDrawing.energy.isFinite {
                scale *= 0.5

                newConfiguration = MappedAccessConfiguration(for: paths, coordinates: adjustedCoordinates())
                newDrawing = Drawing(for: newConfiguration)
            }

//            print("Scaled with:", scale, positionalScale, angularScale, progressScale)

            self.undoManager.beginUndoGrouping()
            self.configuration = newConfiguration
            self.temperature *= 0.9
            self.undoManager.endUndoGrouping()
        }
    }



    // MARK: - Undo & Redo

    private let undoManager: UndoManager = UndoManager()

    public func undo() {
        self.undoManager.undo()
    }

    public func redo() {
        self.undoManager.redo()
    }

    public func removeAllActions() {
        self.undoManager.removeAllActions()
    }
}
