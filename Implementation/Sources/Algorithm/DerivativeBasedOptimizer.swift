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
        let configuration = VectorAccessConfiguration(for: configuration)

        self.raw = configuration

        precondition(drawing.energy.isFinite)
    }

    public convenience init(for paths: GreedilyRealizableSequenceOfPaths) {
        let builder = RandomizedConfigurationBuilder(for: paths)
        let configuration = builder.configuration

        self.init(from: configuration)
    }



    // MARK: - Properties

    private var raw: VectorAccessConfiguration

    public var configuration: MappedAccessConfiguration {
        return self.raw.mapped
    }

    public var drawing: Drawing {
        return Drawing(for: self.configuration)
    }


    // MARK: - Hill Climbing

    public var numberOfDimensions: Int {
        return self.raw.count
    }

    private func derivative(of c0: VectorAccessConfiguration, at index: Int, dx: Double) -> Double {
        var c1 = c0
        c1[index] += dx

        let y0 = Drawing(for: c0.mapped).energy
        let y1 = Drawing(for: c1.mapped).energy

        return (y1 - y0) / dx
    }

    @discardableResult
    public func step() -> Double {
        let oldValue = self.raw
        var newValue = oldValue

        let count = oldValue.count
        var gradient = Array(repeating: 0 as Double, count: count)

        for index in 0..<count {
            gradient[index] = self.derivative(of: oldValue, at: index, dx: 0.0001)
            newValue[index] -= 0.001 * gradient[index]
        }

        do {
            self.undoManager.beginUndoGrouping()
            self.raw = newValue
            self.undoManager.endUndoGrouping()
            
            return 0
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
