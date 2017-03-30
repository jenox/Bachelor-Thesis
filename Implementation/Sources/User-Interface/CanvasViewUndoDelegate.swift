import Foundation


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public protocol CanvasViewUndoDelegate: class {
    var undoManager: UndoManager? { get }
}
