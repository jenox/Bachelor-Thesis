//
//  Copyright © 2017 Christian Schnorr.
//

import CoreGraphics


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public struct ForceDirectedDrawing {
    public typealias Graph = UndirectedGraph
    public typealias Vertex = Graph.Vertex
    public typealias Edge = Graph.Edge
    public typealias Path = Graph.Path


    // MARK: - Initialization

    public init(for configuration: MappedAccessConfiguration) {
        var graph = Graph()
        var locations: [Vertex: CGPoint] = [:]
        var lengths: [Edge: CGFloat] = [:]
        var arcs: [Path: CircularArc] = [:]
        var verticesAreOrderedCorrectly = true

        for (vertex, location) in configuration.locations {
            graph.insert(vertex)
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

                    graph.insert(head)
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

                graph.insert(edge)
                lengths[edge] = fabs(delta) * length
            }

            arcs[path] = arc
        }

        self.graph = graph
        self.locations = locations
        self.lengths = lengths
        self.arcs = arcs
        self.verticesAreOrderedCorrectly = verticesAreOrderedCorrectly
    }



    // MARK: - Stored Properties

    fileprivate let graph: Graph
    fileprivate let locations: [Vertex: CGPoint]
    fileprivate let lengths: [Edge: CGFloat]
    fileprivate let arcs: [Path: CircularArc]
    fileprivate let verticesAreOrderedCorrectly: Bool



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



    // MARK: - Energy

    public var hasFiniteEnergy: Bool {
        if !self.verticesAreOrderedCorrectly { return false }

        for vertex in self.graph.vertices {
            let force = self.force(actingOn: vertex)

            if !force.dx.isFinite { return false }
            if !force.dy.isFinite { return false }
        }

        return true
    }



    // MARK: - Forces

    public func force(actingOn vertex: Vertex) -> CGVector {
        var force = CGVector.zero

        for other in self.graph.vertices where other !== vertex {
            let p = self.location(of: vertex)
            let q = self.location(of: other)

            let direction = -CGVector(from: p, to: q).normalized
            let scale = self.strengthOfRepulsiveForce(distance: p.distance(to: q))

            force += scale * direction
        }

        for edge in self.graph.edges(incidentTo: vertex) where !edge.isLoop {
            let p = self.location(of: vertex)
            let q = self.location(of: edge.head(from: vertex))

            let direction = -CGVector(from: p, to: q).normalized
            let scale = self.strengthOfAttractiveForce(length: self.length(of: edge))

            force += scale * direction
        }

        return force
    }

    private func strengthOfAttractiveForce(length: CGFloat) -> CGFloat {
        let k = 100 as CGFloat

        return -1 * k * log(length / k)
    }

    private func strengthOfRepulsiveForce(distance: CGFloat) -> CGFloat {
        return 100000 / pow(distance, 2)
    }
}
