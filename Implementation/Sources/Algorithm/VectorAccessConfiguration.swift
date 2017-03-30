import CoreGraphics


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public struct VectorAccessConfiguration: ConfigurationProtocol {
    public typealias Graph = UndirectedGraph
    public typealias Vertex = Graph.Vertex
    public typealias Edge = Graph.Edge
    public typealias Path = Graph.Path


    // MARK: - Stored Properties

    public let paths: GreedilyRealizableSequenceOfPaths
    private(set) public var coordinates: [GeneralizedCoordinate]



    // MARK: - Initialization

    public init(for configuration: MappedAccessConfiguration) {
        var coordinates: [GeneralizedCoordinate] = []

        for (vertex, location) in configuration.locations {
            coordinates.append(.x(vertex, location.x))
            coordinates.append(.y(vertex, location.y))
        }

        for (path, angle) in configuration.angles {
            coordinates.append(.angle(path, angle))
        }

        for (vertex, progress) in configuration.progresses {
            coordinates.append(.progress(vertex, progress))
        }

        self.paths = configuration.paths
        self.coordinates = coordinates
    }



    // MARK: - Random Access

    public var count: Int {
        return self.coordinates.count
    }

    public subscript(index: Int) -> Double {
        get {
            return self.coordinates[index].value
        }
        set {
            self.coordinates[index].value = newValue
        }
    }

    public func clone() -> VectorAccessConfiguration {
        return self
    }

    public func evaluate() -> Double {
        let drawing = Drawing(for: self.mapped)
        let energy = drawing.energy

        return Double(energy)
    }



    // MARK: - Mapped Access

    public var mapped: MappedAccessConfiguration {
        return MappedAccessConfiguration(for: self.paths, coordinates: self.coordinates)
    }
}
