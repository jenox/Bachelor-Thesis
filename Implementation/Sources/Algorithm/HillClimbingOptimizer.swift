import Foundation


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public final class HillClimbingOptimizer: Optimizer {
    public typealias Graph = UndirectedGraph
    public typealias Vertex = Graph.Vertex
    public typealias Edge = Graph.Edge
    public typealias Path = Graph.Path


    // MARK: - Initialization

    public init(from configuration: MappedAccessConfiguration) {
        let drawing = Drawing(for: configuration)
        let configuration = VectorAccessConfiguration(for: configuration)

        precondition(drawing.energy.isFinite)

        self.climber = GenericHillClimber(from: configuration, mode: .minimize)
    }



    // MARK: - Properties

    private var climber: GenericHillClimber<VectorAccessConfiguration>

    public var configuration: MappedAccessConfiguration {
        return self.climber.configuration.mapped
    }



    // MARK: - Hill Climbing

    public var numberOfDimensions: Int {
        return self.climber.numberOfDimensions
    }

    public func step() {
        self.climber.climb()
    }



    // MARK: - Undo & Redo

    public func undo() {
        self.climber.undo()
    }

    public func redo() {
        self.climber.redo()
    }

    public func removeAllActions() {
        self.climber.removeAllActions()
    }
}
