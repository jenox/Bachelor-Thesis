import Foundation


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
extension Document {
    public func configuration(from data: Data) throws -> MappedAccessConfiguration {
        guard let parser = Parser(with: data) else {
            throw Error.genericParserError
        }

        guard let configuration = parser.configuration else {
            throw Error.pathsNotGreedilyRealizable
        }

        return configuration
    }

    public func data(for configuration: MappedAccessConfiguration) -> Data {
        return Builder(for: configuration).data
    }

    private enum Error: Swift.Error {
        case genericParserError
        case pathsNotGreedilyRealizable
    }
}



// MARK: - Parser

private class Parser: NSObject, XMLParserDelegate {
    public init?(with data: Data) {
        super.init()

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        guard case .doneWithDocument = self.state else {
            return nil
        }
    }

    private typealias Graph = UndirectedGraph
    private typealias Vertex = Graph.Vertex
    private typealias Edge = Graph.Edge
    private typealias Path = Graph.Path

    private var paths: [Path] = []
    private var locations: [Vertex: CGPoint] = [:]
    private var progresses: [Vertex: CGFloat] = [:]
    private var angles: [Path: CGAngle] = [:]

    private var vertices: [String: Vertex] = [:]
    private var working: (CGAngle, [Vertex])? = nil

    fileprivate var configuration: MappedAccessConfiguration? {
        guard let paths = try? GreedilyRealizableSequenceOfPaths(with: self.paths) else {
            return nil
        }

        guard Set(self.angles.keys) == Set(paths) else {
            return nil
        }

        guard Set(self.progresses.keys) == Set(paths.constrainedVertices) else {
            return nil
        }

        guard Set(self.locations.keys) == Set(paths.unconstrainedVertices) else {
            return nil
        }

        var configuration = MappedAccessConfiguration(for: paths)
        configuration.locations = self.locations
        configuration.progresses = self.progresses
        configuration.angles = self.angles

        return configuration
    }

    private enum State {
        case waitingForDocument
        case waitingForConfiguration
        case parsingConfiguration
        case parsingPath
        case parsingVertex
        case doneWithConfiguration
        case doneWithDocument
        case failed
    }

    private var state: State = .waitingForDocument

    public func parserDidStartDocument(_ parser: XMLParser) {
        guard case .waitingForDocument = self.state else {
            preconditionFailure()
        }

        self.state = .waitingForConfiguration
    }

    public func parser(_ parser: XMLParser, didStartElement tag: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        if tag == "configuration" {
            guard case .waitingForConfiguration = self.state else {
                print("error: abort 1")
                return parser.abortParsing()
            }

            self.state = .parsingConfiguration
        }
        else if tag == "path" {
            guard case .parsingConfiguration = self.state else {
                print("error: abort 2")
                return parser.abortParsing()
            }

            guard let angle = self.angle(from: attributes) else {
                print("error: abort 3", attributes)
                return parser.abortParsing()
            }

            self.state = .parsingPath
            self.working = (angle, [])
        }
        else if tag == "vertex" {
            guard case .parsingPath = self.state else {
                print("error: abort 4")
                return parser.abortParsing()
            }

            guard let name = self.name(from: attributes) else {
                print("error: abort 5")
                return parser.abortParsing()
            }

            let vertex = self.vertices[name] ?? Vertex(name: name)

            if let progress = self.progress(from: attributes) {
                self.progresses[vertex] = progress
            }

            if let location = self.location(from: attributes) {
                self.locations[vertex] = location
            }

            self.state = .parsingVertex
            self.working!.1.append(vertex)
            self.vertices[name] = vertex
        }
    }

    public func parser(_ parser: XMLParser, didEndElement tag: String, namespaceURI: String?, qualifiedName: String?) {
        if tag == "vertex" {
            guard case .parsingVertex = self.state else {
                print("error: abort 6")
                return parser.abortParsing()
            }

            self.state = .parsingPath
        }
        else if tag == "path" {
            guard case .parsingPath = self.state else {
                print("error: abort 7")
                return parser.abortParsing()
            }

            let angle = self.working!.0
            let vertices = self.working!.1

            guard vertices.count >= 2 && Set(vertices).count == vertices.count else {
                print("error: abort 8")
                return parser.abortParsing()
            }

            var path = Path(from: vertices.first!)

            for vertex in vertices.dropFirst() {
                let edge = Edge(between: path.head, and: vertex)
                path.append(edge)
            }

            self.paths.append(path)
            self.angles[path] = angle

            self.state = .parsingConfiguration
            self.working = nil
        }
        else if tag == "configuration" {
            guard case .parsingConfiguration = self.state else {
                print("error: abort 9")
                return parser.abortParsing()
            }

            self.state = .doneWithConfiguration
        }
    }

    public func parserDidEndDocument(_ parser: XMLParser) {
        guard case .doneWithConfiguration = self.state else {
            return self.state = .failed
        }

        self.state = .doneWithDocument
    }

    public func parser(_ parser: XMLParser, parseErrorOccurred error: Error) {
        self.state = .failed
    }

    private func name(from attributes: [String: String]) -> String? {
        guard let text = attributes["name"] else {
            return nil
        }

        return text
    }

    private func location(from attributes: [String: String]) -> CGPoint? {
        guard let text = attributes["location"] else {
            return nil
        }

        let point = NSPointFromString(text)

        if NSStringFromPoint(point) == text {
            return point
        }
        else {
            return nil
        }
    }

    private func progress(from attributes: [String: String]) -> CGFloat? {
        guard let text = attributes["progress"] else {
            return nil
        }

        if let progress = Double(text) {
            return CGFloat(progress)
        }
        else {
            return nil
        }
    }

    private func angle(from attributes: [String: String]) -> CGAngle? {
        guard let text = attributes["angle"] else {
            return nil
        }

        if let degrees = Double(text) {
            return CGAngle(degrees: CGFloat(degrees))
        }
        else {
            return nil
        }
    }
}



// MARK: - Builder

private class Builder {
    private typealias Graph = UndirectedGraph
    private typealias Vertex = Graph.Vertex
    private typealias Edge = Graph.Edge
    private typealias Path = Graph.Path

    public init(for configuration: MappedAccessConfiguration) {
        let body = XMLElement(name: "configuration")

        self.configuration = configuration

        self.document = XMLDocument()
        self.document.characterEncoding = "utf-8"
        self.document.addChild(body)

        for path in configuration.paths {
            self.add(path, to: body)
        }
    }

    private func add(_ path: Path, to parent: XMLElement) {
        let element = XMLElement(name: "path")

        do {
            let angle = self.configuration.angles[path]!

            let attribute = XMLNode(kind: .attribute)
            attribute.name = "angle"
            attribute.stringValue = String(describing: angle.degrees)

            element.addAttribute(attribute)
        }

        for vertex in path.vertices {
            self.add(vertex, in: path, to: element)
        }

        parent.addChild(element)
    }

    private func add(_ vertex: Vertex, in path: Path, to parent: XMLElement) {
        let element = XMLElement(name: "vertex")

        do {
            let name = vertex.name

            let attribute = XMLNode(kind: .attribute)
            attribute.name = "name"
            attribute.stringValue = name

            element.addAttribute(attribute)
        }

        if self.configuration.paths.path(placing: vertex) != path {
        }
        else if self.configuration.paths.constrainedVertices.contains(vertex) {
            let progress = self.configuration.progresses[vertex]!

            let attribute = XMLNode(kind: .attribute)
            attribute.name = "progress"
            attribute.stringValue = String(describing: progress)

            element.addAttribute(attribute)
        }
        else if self.configuration.paths.unconstrainedVertices.contains(vertex) {
            let location = self.configuration.locations[vertex]!

            let attribute = XMLNode(kind: .attribute)
            attribute.name = "location"
            attribute.stringValue = NSStringFromPoint(location)

            element.addAttribute(attribute)
        }

        parent.addChild(element)
    }

    private let configuration: MappedAccessConfiguration
    private let document: XMLDocument

    public var data: Data {
        return document.xmlData
    }
}
