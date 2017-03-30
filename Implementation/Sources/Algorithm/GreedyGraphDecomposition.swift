import Swift


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public struct GreedyGraphDecomposition {
    public typealias Graph = UndirectedGraph
    public typealias Vertex = Graph.Vertex
    public typealias Edge = Graph.Edge
    public typealias Path = Graph.Path


    // MARK: - Initialization

    public init(of graph: Graph) {
        precondition(graph.edges(matching: { $0.isLoop }).isEmpty)

        var paths: [Path] = []
        var edges: Set<Edge> = []
        var vertices: Set<Vertex> = []

        var remaining: [Vertex: Int] = [:]
        for vertex in graph.vertices {
            remaining[vertex] = graph.degree(of: vertex)
        }

        while let u = graph.vertices.filter({ remaining[$0]! > 0 }).min(by: { remaining[$0]! < remaining[$1]! }) {
            for e in graph.edges(incidentTo: u) {
                guard !edges.contains(e) else { continue }

                var path = Path(from: u)
                path.append(e)

                remaining[e.first]! -= 1
                remaining[e.second]! -= 1

                edges.insert(e)
                vertices.insert(u)

                append:
                while !vertices.contains(path.head) {
                    vertices.insert(path.head)

                    for f in graph.edges(incidentTo: path.head) {
                        let w = f.head(from: path.head)

                        guard !edges.contains(f) else { continue }
                        guard !path.contains(w) else { continue }

                        path.append(f)
                        edges.insert(f)

                        remaining[f.first]! -= 1
                        remaining[f.second]! -= 1

                        continue append
                    }

                    break
                }

                vertices.insert(path.head)
                paths.append(path)
            }
        }

        assert(graph.numberOfVertices == vertices.count)
        assert(graph.numberOfEdges == edges.count)
        assert(graph.numberOfEdges == paths.reduce(0, { $0 + $1.numberOfEdges }))

        print(paths)

        self.paths = try! GreedilyRealizableSequenceOfPaths(with: paths)
    }



    // MARK: - Decomposition

    public let paths: GreedilyRealizableSequenceOfPaths
}
