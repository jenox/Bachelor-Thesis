import Foundation


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
extension UndirectedGraph {
    public init?(data: Data) {
        guard let parser = GraphMLParser(data: data) else {
            return nil
        }

        self.init()

        var vertices: [String: Vertex] = [:]

        for name in parser.vertices {
            let vertex = Vertex(name: name)
            vertices[name] = vertex

            self.insert(vertex)
        }

        for (first, second) in parser.edges {
            self.insert(Edge(between: vertices[first]!, and: vertices[second]!))
        }
    }
}



// MARK: - Parser

private class GraphMLParser: NSObject, XMLParserDelegate {
    public init?(data: Data) {
        super.init()

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        guard case .doneWithDocument(let vertices, let edges) = self.state else {
            return nil
        }

        for (source, target) in edges {
            guard vertices.contains(source) else {
                return nil
            }

            guard vertices.contains(target) else {
                return nil
            }
        }
    }

    private enum State {
        case waitingForDocument
        case waitingForGraphML
        case waitingForGraph
        case parsingGraph(Set<String>, [(String, String)])
        case doneWithGraph(Set<String>, [(String, String)])
        case doneWithGraphML(Set<String>, [(String, String)])
        case doneWithDocument(Set<String>, [(String, String)])
        case failed
    }

    private var state: State = .waitingForDocument

    public var vertices: Set<String> {
        guard case .doneWithDocument(let vertices, _) = self.state else {
            preconditionFailure()
        }

        return vertices
    }

    public var edges: [(String, String)] {
        guard case .doneWithDocument(_, let edges) = self.state else {
            preconditionFailure()
        }

        return edges
    }

    public func parserDidStartDocument(_ parser: XMLParser) {
        guard case .waitingForDocument = self.state else {
            preconditionFailure()
        }

        self.state = .waitingForGraphML
    }

    public func parser(_ parser: XMLParser, didStartElement tag: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        if tag == "graphml" {
            guard case .waitingForGraphML = self.state else {
                return parser.abortParsing()
            }

            self.state = .waitingForGraph
        }
        else if tag == "graph" {
            guard case .waitingForGraph = self.state else {
                return parser.abortParsing()
            }

            self.state = .parsingGraph([], [])
        }
        else if tag == "node" {
            guard case .parsingGraph(var vertices, let edges) = self.state else {
                return parser.abortParsing()
            }

            guard let name = attributes["id"] else {
                return parser.abortParsing()
            }

            guard vertices.insert(name).inserted else {
                return parser.abortParsing()
            }

            self.state = .parsingGraph(vertices, edges)
        }
        else if tag == "edge" {
            guard case .parsingGraph(let vertices, var edges) = self.state else {
                return parser.abortParsing()
            }

            guard let source = attributes["source"] else {
                return parser.abortParsing()
            }

            guard let target = attributes["target"] else {
                return parser.abortParsing()
            }

            edges.append((source, target))

            self.state = .parsingGraph(vertices, edges)
        }
    }

    public func parser(_ parser: XMLParser, didEndElement tag: String, namespaceURI: String?, qualifiedName: String?) {
        if tag == "graph" {
            guard case .parsingGraph(let vertices, let edges) = self.state else {
                return parser.abortParsing()
            }

            self.state = .doneWithGraph(vertices, edges)
        }
        else if tag == "graphml" {
            guard case .doneWithGraph(let vertices, let edges) = self.state else {
                return parser.abortParsing()
            }

            self.state = .doneWithGraphML(vertices, edges)
        }
    }

    public func parserDidEndDocument(_ parser: XMLParser) {
        guard case .doneWithGraphML(let vertices, let edges) = self.state else {
            return self.state = .failed
        }

        self.state = .doneWithDocument(vertices, edges)
    }

    public func parser(_ parser: XMLParser, parseErrorOccurred error: Error) {
        self.state = .failed
    }
}
