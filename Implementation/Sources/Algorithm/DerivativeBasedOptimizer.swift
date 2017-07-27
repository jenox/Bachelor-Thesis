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



    // MARK: - Hill Climbing

    public func step() {
        let paths = self.configuration.paths
        let coordinates = VectorAccessConfiguration(for: self.configuration).coordinates

        let generalizedForces = self.generalizedForces

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
                        copy.value += Double(scale * positionalScale * force)
                    case .angle:
                        copy.value += Double(scale * angularScale * force)
                    case .progress:
                        copy.value += Double(scale * progressScale * force)
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

    internal var generalizedForces: [GeneralizedCoordinate: CGFloat] {
        let paths = self.configuration.paths
        let coordinates = VectorAccessConfiguration(for: self.configuration).coordinates

        let oldConfiguration = MappedAccessConfiguration(for: paths, coordinates: coordinates)
        let oldEnergy = Drawing(for: oldConfiguration).energy

        let step = 1e-8 as CGFloat
        var derivatives: [GeneralizedCoordinate: CGFloat] = [:]

        for (index, coordinate) in coordinates.enumerated() {
            var newCoordinates = coordinates
            newCoordinates[index].value += Double(step)

            let newConfiguration = MappedAccessConfiguration(for: paths, coordinates: newCoordinates)
            let newEnergy = Drawing(for: newConfiguration).energy

            derivatives[coordinate] = -CGFloat(newEnergy - oldEnergy) / step
        }

        return derivatives
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
