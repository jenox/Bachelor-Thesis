import AppKit


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public class Document: NSDocument, CanvasViewUndoDelegate {
    private let canvas: CanvasView
    private let viewController: NSViewController

    private let window: NSWindow
    private let windowController: NSWindowController


    // MARK: - Object Lifecycle

    public override init() {
        self.canvas = CanvasView()

        self.viewController = NSViewController(nibName: nil, bundle: nil)!
        self.viewController.view = self.canvas

        self.window = NSWindow(contentViewController: self.viewController)
        self.window.contentMinSize = NSSize(width: 480, height: 360)
        self.window.setContentSize(self.window.minSize)

        self.windowController = NSWindowController(window: self.window)

        super.init()

        self.canvas.delegate = self
    }



    // MARK: - Document Behavior

    public override class func autosavesInPlace() -> Bool {
        return false
    }

    public override func makeWindowControllers() {
        self.addWindowController(self.windowController)
    }

    public override func data(ofType type: String) throws -> Data {
        guard type == "Configuration" else {
            throw Error.other("Can only write configuration files.")
        }

        Swift.print("Saving configuration…")

        return self.data(for: self.canvas.committedConfiguration)
    }

    public override func read(from data: Data, ofType type: String) throws {
        if type == "Configuration" {
            Swift.print("Loading Configuration…")

            let configuration = try self.configuration(from: data)
            let n = configuration.paths.vertices.count
            let m = configuration.paths.edges.count
            let k = configuration.paths.count

            Swift.print("Successfully loaded configuration with \(n) vertices, \(m) edges; \(k) paths.")

            self.canvas.committedConfiguration = configuration
            self.undoManager!.removeAllActions()
        }
        else if type == "Graph" {
            Swift.print("Loading Graph…")

            let graph = try self.graph(from: data)
            let paths = GreedyGraphDecomposition(of: graph).paths
            let configuration = RandomizedConfigurationBuilder(for: paths).configuration

            let n = configuration.paths.vertices.count
            let m = configuration.paths.edges.count
            let k = configuration.paths.count

            Swift.print("Successfully loaded graph with \(n) vertices, \(m) edges; \(k) paths.")

            self.ensureDisplayNameWithout(suffix: ".graphml")
            self.read(other: configuration)
        }
        else if type == "Paths" {
            Swift.print("Loading Paths…")

            let paths = try self.paths(from: data)
            let configuration = RandomizedConfigurationBuilder(for: paths).configuration

            let n = configuration.paths.vertices.count
            let m = configuration.paths.edges.count
            let k = configuration.paths.count

            Swift.print("Successfully loaded paths with \(n) vertices, \(m) edges; \(k) paths.")

            self.ensureDisplayNameWithout(suffix: ".paths")
            self.read(other: configuration)
        }
        else {
            throw Error.other("Unrecognized file type.")
        }
    }



    // MARK: - Helpers

    private func ensureDisplayNameWithout(suffix: String) {
        guard var title = self.displayName else {
            return
        }

        if let range = title.range(of: suffix), range.upperBound == title.endIndex {
            title.removeSubrange(range)
        }

        self.displayName = title
    }

    private func read(other configuration: MappedAccessConfiguration) {
        self.canvas.committedConfiguration = configuration
        self.undoManager!.removeAllActions()

        self.fileURL = nil
        self.updateChangeCount(.changeReadOtherContents)
    }

    private enum Error: Swift.Error {
        case other(String)
    }
}
