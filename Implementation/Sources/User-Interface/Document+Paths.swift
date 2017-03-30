import Foundation


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
extension Document {
    public func paths(from data: Data) throws -> GreedilyRealizableSequenceOfPaths {
        return try Parser(with: data).paths
    }
}



// MARK: - Parser

private class Parser {
    private typealias Graph = UndirectedGraph
    private typealias Vertex = Graph.Vertex
    private typealias Edge = Graph.Edge
    private typealias Path = Graph.Path

    public init(with data: Data) throws {
        guard let text = String(data: data, encoding: .utf8) else {
            throw Error.incorrectEncoding
        }

        var paths: [Path] = []
        var vertices: [String: Vertex] = [:]

        for line in text.components(separatedBy: .newlines) {
            guard !line.isEmpty else {
                continue
            }

            var working: [Vertex] = []

            for word in line.components(separatedBy: "-") {
                let vertex = vertices[word] ?? Vertex(name: word)

                vertices[word] = vertex
                working.append(vertex)
            }

            guard working.count >= 2 && Set(working).count == working.count else {
                throw Error.pathsNotSimple
            }

            var path = Path(from: working.first!)

            for vertex in working.dropFirst() {
                let edge = Edge(between: path.head, and: vertex)

                path.append(edge)
            }

            paths.append(path)
        }

        do {
            self.paths = try GreedilyRealizableSequenceOfPaths(with: paths)
        }
        catch {
            print("not realizable")
            throw Error.pathsNotGreedilyRealizable
        }
    }

    public let paths: GreedilyRealizableSequenceOfPaths

    private enum Error: Swift.Error {
        case incorrectEncoding
        case pathsNotSimple
        case pathsNotGreedilyRealizable
    }
}
