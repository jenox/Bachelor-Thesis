import Foundation


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public final class DerivativeBasedOptimizer: Optimizer {
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



    // MARK: - Stepping

    private func internalVertexToPathMap(in drawing: Drawing) -> [Vertex: Path] {
        var paths: [Vertex: Path] = [:]

        for path in drawing.paths {
            for vertex in path.internalVertices {
                paths[vertex] = path
            }
        }

        return paths
    }

    private func forces(in drawing: Drawing) -> [Vertex: CGVector] {
        var forces: [Vertex: CGVector] = [:]

        for vertex in drawing.graph.vertices {
            forces[vertex] = drawing.force(actingOn: vertex)
        }

        return forces
    }

    public func step() {
        let configuration = self.configuration
        let drawing = Drawing(for: configuration)

        let paths = self.internalVertexToPathMap(in: drawing)
        let traditionalForces = self.forces(in: drawing)

        // Generalized coordinates q_j and forces Q_j
        var coordinates = VectorAccessConfiguration(for: configuration).coordinates
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

        print()
        print("TRADITIONAL FORCES")
        print("==================")

        for (vertex, force) in traditionalForces {
            print("\(vertex):", force)
        }

        print()
        print("GENERALIZED FORCES")
        print("==================")

        for (coordinate, force) in forces {
            print("\(coordinate):", force)
        }

        do {
            var scale1 = 1 as CGFloat
            var scale2 = 1 as CGFloat

            for coordinate in coordinates {
                let force = fabs(forces[coordinate]!)

                switch coordinate {
                case .x: scale1 = min(scale1, 10 / force)
                case .y: scale1 = min(scale1, 10 / force)
                case .angle: scale2 = min(scale2, CGAngle.degrees(10).radians / force)
                case .progress: scale2 = min(scale2, 0.1 / force)
                }
            }

            print("adjusting with scales (\(scale1), \(scale2))")

            for index in coordinates.indices {
                switch coordinates[index] {
                case .x, .y:
                    coordinates[index].rawValue += scale1 * forces[coordinates[index]]!
                case .angle, .progress:
                    coordinates[index].rawValue += scale2 * forces[coordinates[index]]!
                }

            }
        }

        do {
            self.undoManager.beginUndoGrouping()

            self.configuration = MappedAccessConfiguration(for: configuration.paths, coordinates: coordinates)

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
