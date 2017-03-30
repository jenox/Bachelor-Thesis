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
        var locations: [Vertex: CGPoint] = [:]
        var lengths: [Edge: CGFloat] = [:]
        var arcs: [Path: CircularArc] = [:]
        var verticesAreOrderedCorrectly = true

        for (vertex, location) in configuration.locations {
            locations[vertex] = location
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

                    locations[head] = arc.point(for: progress)

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
            }

            arcs[path] = arc
        }

        self.locations = locations
        self.lengths = lengths
        self.arcs = arcs
        self.verticesAreOrderedCorrectly = verticesAreOrderedCorrectly
    }

    private let locations: [Vertex: CGPoint]
    private let lengths: [Edge: CGFloat]
    private let arcs: [Path: CircularArc]
    private let verticesAreOrderedCorrectly: Bool



    // MARK: - Geometric Entities

    public var vertices: Set<Vertex> {
        return Set(self.locations.keys)
    }

    public var edges: Set<Edge> {
        return Set(self.lengths.keys)
    }

    public var paths: Set<Path> {
        return Set(self.arcs.keys)
    }

    public func location(of vertex: Vertex) -> CGPoint {
        return self.locations[vertex]!
    }

    public func length(of edge: Edge) -> CGFloat {
        return self.lengths[edge]!
    }

    public func arc(for path: Path) -> CircularArc {
        return self.arcs[path]!
    }



    // MARK: - Potential Energy

    public var energy: Double {
        guard self.verticesAreOrderedCorrectly else {
            return .infinity
        }

        let vertices = Array(self.locations.keys)
        let edges = Array(self.lengths.keys)
        let paths = Array(self.paths)

        var energy = 0.0

        for i in stride(from: 0, to: vertices.count, by: 1) {
            for j in stride(from: i + 1, to: vertices.count, by: 1) {
                energy += self.repulsion(between: vertices[i], and: vertices[j])
            }
        }

        for edge in edges {
            energy += self.attraction(along: edge)
        }

        for path in paths {
            for vertex in vertices where !path.contains(vertex) {
                energy += self.repulsion(between: vertex, and: path)
            }
        }

        assert(!energy.isNaN)

        return energy
    }

    private func repulsion(between u: Vertex, and v: Vertex) -> Double {
        precondition(u != v)

        let p = self.location(of: u)
        let q = self.location(of: v)
        let distance = p.distance(to: q)
        let c1 = 100000 as CGFloat

        return Double(c1 * 1 / distance)
    }

    private func attraction(along edge: Edge) -> Double {
        let length = self.length(of: edge)

        let k = 100 as CGFloat
        let c2 = 1 as CGFloat

        return Double(c2 * k * (length * log(length / k) - 1) + k * k)
    }

    private func repulsion(between vertex: Vertex, and path: Path) -> Double {
        precondition(!path.contains(vertex))

        let point = self.location(of: vertex)
        let arc = self.arc(for: path)
        let distance = arc.distance(to: point)
        let c3 = 10000 as CGFloat

        return Double(c3 * 1 / distance)
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
