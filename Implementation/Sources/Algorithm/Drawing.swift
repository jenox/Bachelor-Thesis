import CoreGraphics
import Foundation


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public struct Drawing {
    public typealias Graph = UndirectedGraph
    public typealias Vertex = Graph.Vertex
    public typealias Edge = Graph.Edge
    public typealias Path = Graph.Path


    // MARK: - Initialization

    public init(for configuration: MappedAccessConfiguration) {
        var graph = Graph()
        var paths: [Path] = []
        var locations: [Vertex: CGPoint] = [:]
        var lengths: [Edge: CGFloat] = [:]
        var arcs: [Path: CircularArc] = [:]
        var directions: [Vertex: [CGVector]] = [:]
        var verticesAreOrderedCorrectly = true

        for (vertex, location) in configuration.locations {
            locations[vertex] = location
            directions[vertex] = []

            graph.insert(vertex)
        }

        for path in configuration.paths {
            let start = locations[path.tail]!
            let end = locations[path.head]!
            let angle = configuration.angles[path]!

            let arc = CircularArc(from: start, to: end, with: angle)
            let length = arc.length
            var last = 0 as CGFloat

            for index in 1...path.numberOfEdges {
                let head = path.vertices[index]
                let edge = path.edges[index - 1]
                let delta: CGFloat

                if index < path.numberOfEdges {
                    let progress = configuration.progresses[head]!
                    let direction = arc.derivative(for: progress)

                    locations[head] = arc.point(for: progress)
                    directions[head] = [-direction, +direction]

                    graph.insert(head)

                    delta = progress - last
                    last = progress
                }
                else {
                    delta = 1 - last
                }

                if delta <= 0 {
                    verticesAreOrderedCorrectly = false
                }

                lengths[edge] = fabs(delta) * length

                graph.insert(edge)
            }

            directions[path.tail]!.append(+arc.derivative(for: 0))
            directions[path.head]!.append(-arc.derivative(for: 1))
            arcs[path] = arc

            paths.append(path)
        }

        self.graph = graph
        self.paths = paths
        self.locations = locations
        self.lengths = lengths
        self.arcs = arcs
        self.directions = directions
        self.verticesAreOrderedCorrectly = verticesAreOrderedCorrectly
    }



    // MARK: - Stored Properties

    public let graph: Graph
    public let paths: [Path]
    private let locations: [Vertex: CGPoint]
    private let lengths: [Edge: CGFloat]
    private let arcs: [Path: CircularArc]
    private let directions: [Vertex: [CGVector]]
    private let verticesAreOrderedCorrectly: Bool



    // MARK: - Positional Information

    public func location(of vertex: Vertex) -> CGPoint {
        return self.locations[vertex]!
    }

    public func length(of edge: Edge) -> CGFloat {
        return self.lengths[edge]!
    }

    public func arc(for path: Path) -> CircularArc {
        return self.arcs[path]!
    }

    private func directions(at vertex: Vertex) -> [CGVector] {
        return self.directions[vertex]!
    }



    // MARK: - Potential Energy

    public var energy: Double {
        guard self.verticesAreOrderedCorrectly else {
            return .infinity
        }

        let vertices = Array(self.locations.keys)
        let edges = Array(self.lengths.keys)
        let paths = Array(self.paths)

        var energy = 0 as CGFloat

        for i in stride(from: 0, to: vertices.count, by: 1) {
            for j in stride(from: i + 1, to: vertices.count, by: 1) {
                let p = self.location(of: vertices[i])
                let q = self.location(of: vertices[j])
                let distance = p.distance(to: q)

                energy += 2 * self.magnitudeOfRepulsiveEnergyBetweenVertexAndVertex(distance: distance)
            }
        }

        for edge in edges {
            let length = self.length(of: edge)

            energy += self.magnitudeOfAttractiveEnergyForEdge(length: length, desired: 100)
        }

        for path in paths {
            for vertex in vertices where !path.contains(vertex) {
                let point = self.location(of: vertex)
                let arc = self.arc(for: path)
                let distance = arc.distance(to: point)

                energy += self.magnitudeOfRepulsiveEnergyBetweenVertexAndPath(distance: distance)
            }
        }

        assert(!energy.isNaN)

        return Double(energy)
    }

    private func repulsion(between vertex: Vertex, and path: Path) -> Double {
        precondition(!path.contains(vertex))

        let point = self.location(of: vertex)
        let arc = self.arc(for: path)
        let distance = arc.distance(to: point)
        let c3 = 10000 as CGFloat

        return Double(c3 * 1 / distance)
    }

    private func magnitudeOfAttractiveEnergyForEdge(length: CGFloat, desired k: CGFloat) -> CGFloat {
        return 100 * (length * (log(length / k) - 1) + k)
    }

    private func magnitudeOfRepulsiveEnergyBetweenVertexAndVertex(distance: CGFloat) -> CGFloat {
        return 100000 / distance
    }

    private func magnitudeOfRepulsiveEnergyBetweenVertexAndPath(distance: CGFloat) -> CGFloat {
        return 10000 / distance
    }



    // MARK: - Forces

    public func force(actingOn vertex: Vertex) -> CGVector {
        guard self.verticesAreOrderedCorrectly else {
            fatalError("Force acting on vertex is undefined when ordered incorrectly.")
        }

        var force = CGVector.zero

        for other in self.graph.vertices where other !== vertex {
            let p = self.location(of: vertex)
            let q = self.location(of: other)

            let distance = CGVector(from: p, to: q).length
            let direction = -CGVector(from: p, to: q).normalized
            let scale = self.magnitudeOfRepulsiveForceBetweenVertexAndVertex(distance: distance)

            force += scale * direction
        }

        for edge in self.graph.edges(incidentTo: vertex) where !edge.isLoop {
            let p = self.location(of: vertex)
            let q = self.location(of: edge.head(from: vertex))

            let length = self.length(of: edge)
            let direction = -CGVector(from: p, to: q).normalized
            let scale = self.magnitudeOfAttractiveForceAlongEdge(length: length, desired: 100)

            force += scale * direction
        }

        for path in self.paths where !path.contains(vertex) {
            let point = self.location(of: vertex)
            let arc = self.arc(for: path)

            let progress = arc.progress(for: point)
            let closest = arc.point(for: progress)

            let distance = CGVector(from: closest, to: point).length
            let direction = CGVector(from: closest, to: point).normalized
            let scale = self.magnitudeOfRepulsiveForceBetweenVertexAndPath(distance: distance)

            force += scale * direction
        }

        return force
    }

    private func magnitudeOfAttractiveForceAlongEdge(length: CGFloat, desired k: CGFloat) -> CGFloat {
        return 100 * -log(length / k)
    }

    private func magnitudeOfRepulsiveForceBetweenVertexAndVertex(distance: CGFloat) -> CGFloat {
        return 100000 / pow(distance, 2)
    }

    private func magnitudeOfRepulsiveForceBetweenVertexAndPath(distance: CGFloat) -> CGFloat {
        return 10000 / pow(distance, 2)
    }



    // MARK: - Angular Resolution

    private func angles(at vertex: Vertex) -> [CGAngle] {
        let directions = self.directions(at: vertex).sorted(by: { $0.slope < $1.slope })
        var angles: [CGAngle] = []

        for index in directions.indices.dropLast() {
            angles.append(CGAngle(between: directions[index], and: directions[index + 1]))
        }

        angles.append(CGAngle.full - angles.reduce(CGAngle.zero, +))

        return angles
    }

    // 360-0-0 and 0-180-180 are equally bad
    // 300-30-30 and 270-60-30 are equally bad
    private func lombardiness_strict(for angles: [CGAngle]) -> Double {
        let ideal = CGAngle.full / CGFloat(angles.count)
        let smallest = angles.min()!

        return Double(smallest / ideal)
    }

    // 360-0-0 and 0-180-180 are NOT equally bad
    // 300-30-30 and 270-60-30 are NOT equally bad
    private func lombardiness_lenient(for angles: [CGAngle]) -> Double {
        guard angles.count >= 2 else {
            return 1
        }

        let ideal = CGAngle.full / angles.count
        let maximum = 2 * ideal * CGFloat(angles.count - 1)
        let derivation = angles.reduce(CGAngle.zero, { $0 + abs($1 - ideal) })

        return fmin(fmax(1 - Double(derivation / maximum), 0), 1)
    }

    // 360-0-0 and 0-180-180 are equally bad
    // 300-30-30 and 270-60-30 are NOT equally bad
    private func lombardiness(at vertex: Vertex) -> Double {
        let angles = self.angles(at: vertex)
        let l1 = self.lombardiness_strict(for: angles)
        let l2 = self.lombardiness_lenient(for: angles)

        return l1 + l1 * (l2 - l1)
    }

    public var lombardiness: Double {
        let reciprocals = self.graph.vertices.map({ 1 / self.lombardiness(at: $0) })
        let lombardiness = 1 / reciprocals.average

        return fmin(fmax(lombardiness, 0), 1)
    }



    // MARK: - SVG Export

    public var bounds: CGRect {
        return self.bounds(for: .identity)
    }

    public func bounds(for transform: CGAffineTransform) -> CGRect {
        let path = CGMutablePath()

        for (_, arc) in self.arcs {
            path.addPath(arc.path, transform: transform)
        }

        return path.boundingBoxOfPath
    }

    private func dimension(for transform: CGAffineTransform) -> CGFloat {
        let angle = CGAngle(radians: atan2(transform.b, transform.a))
        let transform = CGAffineTransform.identity.rotated(by: angle)
        let bounds = self.bounds(for: transform)
        let dimension = fmax(bounds.width, bounds.height)

        return dimension
    }

    public func svg(for transform: CGAffineTransform) -> Data {
        var bounds = self.bounds(for: transform)
        bounds = bounds.scaled(by: 1.2, around: bounds.center)

        let width = bounds.width.rounded(.up)
        let height = bounds.height.rounded(.up)
        let dimension = self.dimension(for: transform)

        let radius = 4 * dimension / 240
        let stroke = 1 * dimension / 240

        var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(width)\" height=\"\(height)\">"
        svg += "<g transform=\"matrix(1,0,0,-1,0,\(height)),matrix(1,0,0,1,\(-bounds.minX),\(-bounds.minY)),matrix(\(transform.a),\(transform.b),\(transform.c),\(transform.d),\(transform.tx),\(transform.ty))\">"
        svg += "<g fill=\"black\" stroke=\"none\">"

        for (_, location) in self.locations {
            svg += "<circle cx=\"\(location.x)\" cy=\"\(location.y)\" r=\"\(radius)\" />"
        }

        svg += "</g>"
        svg += "<g fill=\"none\" stroke=\"black\" stroke-width=\"\(stroke)\" stroke-linecap=\"round\">"

        for (_, arc) in self.arcs {
            svg += "<path d=\"\(arc.svg)\" />"
        }

        svg += "</g>"
        svg += "</g>"
        svg += "</svg>"

        return svg.data(using: .utf8)!
    }
}



// MARK: - Helpers

extension Array where Element: FloatingPoint {
    public var average: Element {
        if self.isEmpty {
            return 0
        }
        else {
            return self.reduce(0, +) / Element(self.count)
        }
    }
}
