import Foundation


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
extension Document {
    public func graph(from data: Data) throws -> UndirectedGraph {
        if let graph = UndirectedGraph(data: data) {
            return graph
        }
        else {
            throw Error.uncategorized
        }
    }

    private enum Error: Swift.Error {
        case uncategorized
    }
}
