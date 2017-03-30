import Swift


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public struct GreedilyRealizableSequenceOfPaths: Collection, Equatable {
    public typealias Graph = UndirectedGraph
    public typealias Vertex = Graph.Vertex
    public typealias Edge = Graph.Edge
    public typealias Path = Graph.Path


    // MARK: - Initialization

    public init() {
        self.paths = []
        self.edges = []
        self.vertices = []
        self.constrainedVertices = []
        self.unconstrainedVertices = []
    }

    public init(with paths: [Path]) throws {
        var edges: Set<Edge> = []
        var vertices: Set<Vertex> = []
        var constrainedVertices: Set<Vertex> = []
        var unconstrainedVertices: Set<Vertex> = []

        for path in paths {
            guard vertices.isDisjoint(with: path.internalVertices) else {
                print("[ERROR] Internal vertices \(vertices.intersection(path.internalVertices)) already placed")
                throw Error.internalVertexAlreadyPlaced
            }

            guard edges.isDisjoint(with: path.edges) else {
                print("[ERROR] Paths are not edge-disjoint.")
                throw Error.pathsAreNotEdgeDisjoint
            }

            if !vertices.contains(path.tail) {
                unconstrainedVertices.insert(path.tail)
            }

            if !vertices.contains(path.head) {
                unconstrainedVertices.insert(path.head)
            }

            constrainedVertices.formUnion(path.internalVertices)

            vertices.formUnion(path.vertices)
            edges.formUnion(path.edges)
        }

        self.paths = paths
        self.edges = edges
        self.vertices = vertices
        self.constrainedVertices = constrainedVertices
        self.unconstrainedVertices = unconstrainedVertices

        assert(constrainedVertices.union(unconstrainedVertices) == vertices)
        assert(constrainedVertices.intersection(unconstrainedVertices).count == 0)
    }



    // MARK: - Stored Properties

    private let paths: [Path]
    public let edges: Set<Edge>
    public let vertices: Set<Vertex>
    public let constrainedVertices: Set<Vertex>
    public let unconstrainedVertices: Set<Vertex>



    // MARK: - Convience

    /// - Complexity: O(k), where k is the number of paths.
    public func path(placing vertex: Vertex) -> Path {
        for path in self.paths {
            if path.contains(vertex) {
                return path
            }
        }

        fatalError()
    }



    // MARK: - Collection

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return self.paths.count
    }

    public func index(before index: Int) -> Int {
        return index - 1
    }

    public func index(after index: Int) -> Int {
        return index + 1
    }

    public subscript(index: Int) -> Path {
        return self.paths[index]
    }

    public func makeIterator() -> IndexingIterator<[Path]> {
        return self.paths.makeIterator()
    }



    // MARK: - Equatable

    public static func ==(lhs: GreedilyRealizableSequenceOfPaths, rhs: GreedilyRealizableSequenceOfPaths) -> Bool {
        return lhs.paths == rhs.paths
    }



    // MARK: - Error

    public enum Error: Swift.Error {
        case pathsAreNotEdgeDisjoint
        case internalVertexAlreadyPlaced
    }
}
