import CoreGraphics


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public final class RandomizedConfigurationBuilder {
    public typealias Graph = UndirectedGraph
    public typealias Vertex = Graph.Vertex
    public typealias Edge = Graph.Edge
    public typealias Path = Graph.Path


    // MARK: - Initialization

    public init(for paths: GreedilyRealizableSequenceOfPaths) {
        self.paths = paths

        var done = false

        while !done {
            self.locations = [:]
            self.progresses = [:]
            self.angles = [:]
            self.annotations = [:]
            self.arcs = [:]

            do {
                try self.layoutUnconstrainedVertices()
                try self.layoutConstrainedVertices()

                done = true
            }
            catch {
                Swift.print("Couldn't find valid configuration in reasonable time, retrying.")
            }
        }
    }



    // MARK: - Algorithm

    private let paths: GreedilyRealizableSequenceOfPaths
    private var locations: [Vertex: CGPoint] = [:]
    private var progresses: [Vertex: CGFloat] = [:]
    private var angles: [Path: CGAngle] = [:]

    private var annotations: [Vertex: CGPoint] = [:]
    private var arcs: [Path: CircularArc] = [:]

    private func layoutUnconstrainedVertices() throws {
        let radius = 100 as CGFloat

        outer:
        for vertex in self.paths.unconstrainedVertices {
            var count = 0

            while count < 5 {
                let angle = self.randomFloat(within: 0...1) * CGAngle.full
                let location = CGVector(dx: radius, dy: 0).rotated(by: angle).pointee

                if self.allows(annotation: location) {
                    self.locations[vertex] = location
                    self.annotations[vertex] = location

                    continue outer
                }
                else {
                    count += 1
                }
            }

            throw Error.nonreasonableEffort
        }
    }

    private func layoutConstrainedVertices() throws {
        for path in self.paths {
            try self.layoutConstrainedVertices(on: path)
        }
    }

    private func layoutConstrainedVertices(on path: Path) throws {
        let arc = try self.arc(for: path)
        let progresses = try self.progresses(for: path, on: arc)

        for vertex in path.internalVertices {
            let progress = progresses[vertex]!

            self.progresses[vertex] = progress
            self.annotations[vertex] = arc.point(for: progress)
        }

        self.angles[path] = arc.angle
        self.arcs[path] = arc
    }

    private func arc(for path: Path) throws -> CircularArc {
        let start = self.annotations[path.tail]!
        let end = self.annotations[path.head]!
        var count = 0

        while count < 20 {
            let angle = self.randomAngle()
            let arc = CircularArc(from: start, to: end, with: angle)

            if self.allows(arc, for: path) {
                return arc
            }
            else {
                count += 1
            }
        }

        throw Error.nonreasonableEffort
    }

    private func progresses(for path: Path, on arc: CircularArc) throws -> [Vertex: CGFloat] {
        var progresses: [Vertex: CGFloat] = [:]

        outer:
        for vertex in path.internalVertices {
            let step = 1 / CGFloat(path.numberOfEdges - 1)
            let minimum = step * CGFloat(progresses.count)
            let maximum = step * CGFloat(progresses.count + 1)
            var count = 0

            while count < 20 {
                let progress = minimum + self.randomProgress() * (maximum - minimum)
                let point = arc.point(for: progress)

                if self.allows(annotation: point) {
                    progresses[vertex] = progress

                    continue outer
                }
                else {
                    count += 1
                }
            }

            throw Error.nonreasonableEffort
        }

        return progresses
    }

    private func randomFloat(within range: ClosedRange<CGFloat>) -> CGFloat {
        let factor = CGFloat(1 + arc4random_uniform(UInt32.max - 1)) / CGFloat(UInt32.max)
        let number = range.lowerBound + factor * (range.upperBound - range.lowerBound)

        return number
    }

    private func randomAngle() -> CGAngle {
        let x = self.randomFloat(within: -1...1)
        let y = 45 * abs(x) / x * pow(abs(x), 0.4)

        return CGAngle(degrees: y)
    }

    private func randomProgress() -> CGFloat {
        let x = self.randomFloat(within: -1...1)
        let y = 0.5 + 0.5 * abs(x) / x * pow(abs(x), 2)

        return y
    }

    private func allows(annotation point: CGPoint) -> Bool {
        for (_, existing) in self.annotations {
            if fabs(existing.distance(to: point)) < 1e-4 {
                return false
            }
        }

        for (_, arc) in self.arcs {
            if fabs(arc.distance(to: point)) < 1e-4 {
                return false
            }
        }

        return true
    }

    private func allows(_ arc: CircularArc, for path: Path) -> Bool {

        // only required for multiple paths being single-edged, connecting the same endpoints
        for (_, existing) in self.arcs {
            if existing == arc || existing == arc.reversed() {
                return false
            }
        }

        for (vertex, point) in self.annotations where !path.contains(vertex) {
            if fabs(arc.distance(to: point)) < 1e-4 {
                return false
            }
        }

        return true
    }



    // MARK: - Public Interface

    public var configuration: MappedAccessConfiguration {
        var configuration = MappedAccessConfiguration(for: self.paths)
        configuration.locations = self.locations
        configuration.progresses = self.progresses
        configuration.angles = self.angles

        return configuration
    }



    // MARK: - Error

    public enum Error: Swift.Error {
        case nonreasonableEffort
    }
}
