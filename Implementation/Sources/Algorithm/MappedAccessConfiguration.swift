import CoreGraphics


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public struct MappedAccessConfiguration: Equatable {
    public typealias Graph = UndirectedGraph
    public typealias Vertex = Graph.Vertex
    public typealias Edge = Graph.Edge
    public typealias Path = Graph.Path


    // MARK: - Initialization

    public init() {
        self.paths = GreedilyRealizableSequenceOfPaths()
        self.locations = [:]
        self.progresses = [:]
        self.angles = [:]
    }

    public init(for paths: GreedilyRealizableSequenceOfPaths) {
        var locations: [Vertex: CGPoint] = [:]
        var progresses: [Vertex: CGFloat] = [:]
        var angles: [Path: CGAngle] = [:]

        for vertex in paths.unconstrainedVertices {
            locations[vertex] = .zero
        }

        for vertex in paths.constrainedVertices {
            progresses[vertex] = 0.5
        }

        for path in paths {
            angles[path] = .zero
        }

        self.paths = paths
        self.locations = locations
        self.progresses = progresses
        self.angles = angles
    }

    public init(for paths: GreedilyRealizableSequenceOfPaths, coordinates: [GeneralizedCoordinate]) {
        var locations: [Vertex: CGPoint] = [:]
        var progresses: [Vertex: CGFloat] = [:]
        var angles: [Path: CGAngle] = [:]

        var xs: [Vertex: CGFloat] = [:]
        var ys: [Vertex: CGFloat] = [:]

        for coordinate in coordinates {
            switch coordinate {
            case .x(let vertex, let x):
                xs[vertex] = x
            case .y(let vertex, let y):
                ys[vertex] = y
            case .angle(let path, let angle):
                angles[path] = angle
            case .progress(let vertex, let progress):
                progresses[vertex] = progress
            }
        }

        for vertex in paths.unconstrainedVertices {
            locations[vertex] = CGPoint(x: xs[vertex]!, y: ys[vertex]!)
        }

        self.paths = paths
        self.locations = locations
        self.progresses = progresses
        self.angles = angles

        assert(Set(locations.keys) == Set(paths.unconstrainedVertices))
        assert(Set(progresses.keys) == Set(paths.constrainedVertices))
        assert(Set(angles.keys) == Set(paths))
    }



    // MARK: - Stored Properties

    public let paths: GreedilyRealizableSequenceOfPaths
    public var locations: [Vertex: CGPoint]
    public var progresses: [Vertex: CGFloat]
    public var angles: [Path: CGAngle]



    // MARK: - Derived Configurations

    public func with(_ vertex: Vertex, at point: CGPoint) -> MappedAccessConfiguration? {
        precondition(self.paths.vertices.contains(vertex))

        if self.paths.unconstrainedVertices.contains(vertex) {
            var copy = self
            copy.locations[vertex] = point

            return copy
        }
        else {
            let drawing = Drawing(for: self)
            let path = self.paths.path(placing: vertex)

            if let arc = drawing.arc(for: path).intersecting(point) {
                var copy = self
                copy.angles[path] = arc.angle
                copy.progresses[vertex] = arc.progress(for: point)

                return copy
            }
            else {
                return nil
            }
        }
    }

    public func with(_ path: Path, intersecting point: CGPoint) -> MappedAccessConfiguration? {
        precondition(self.paths.contains(path))

        let drawing = Drawing(for: self)

        if let arc = drawing.arc(for: path).intersecting(point) {
            var copy = self
            copy.angles[path] = arc.angle

            return copy
        }
        else {
            return nil
        }
    }



    // MARK: - Equtable

    public static func ==(lhs: MappedAccessConfiguration, rhs: MappedAccessConfiguration) -> Bool {
        if lhs.paths != rhs.paths {
            return false
        }
        else if lhs.locations != rhs.locations {
            return false
        }
        else if lhs.progresses != rhs.progresses {
            return false
        }
        else if lhs.angles != rhs.angles {
            return false
        }
        else {
            return true
        }
    }
}
